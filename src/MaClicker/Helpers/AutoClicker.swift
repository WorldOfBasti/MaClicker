//
//  AutoClicker.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 13.09.24.
//  Github: https://github.com/WorldOfBasti
//

import Foundation
import AppKit
import Sauce

final class AutoClicker {
    private var activationKey: Key?        { Key(QWERTYKeyCode: UserDefaults.standard.integer(forKey: "ActivationKey")) }
    private var mode: ClickerMode          { ClickerMode(rawValue: UserDefaults.standard.integer(forKey: "ModeIndex")) ?? .toggle }
    private var useClickLimit: Bool        { UserDefaults.standard.bool(forKey: "LimitEnabled") }
    private var clickLimit: Int            { UserDefaults.standard.integer(forKey: "ClickLimit") }
    private var mouseButton: CGMouseButton { UserDefaults.standard.integer(forKey: "MouseButtonIndex") == 1 ? .right : .left }
    private var cps: Int                   { UserDefaults.standard.integer(forKey: "ClicksPerSecond") }

    // Humanise settings
    private var humaniseEnabled: Bool { UserDefaults.standard.bool(forKey: "HumaniseEnabled") }
    private var fatigueEnabled:  Bool { UserDefaults.standard.bool(forKey: "FatigueEnabled") }
    private var noiseEnabled:    Bool { UserDefaults.standard.bool(forKey: "NoiseEnabled") }
    private var collapseEnabled: Bool { UserDefaults.standard.bool(forKey: "CollapseEnabled") }

    // Standard clicker state
    private var clickerTimer: Timer?
    private var clickCount = 0
    private var isLocked = false

    // Humanise session state
    private var sessionStart: Date?
    private var humaniseClickCount = 0
    private var humaniseWorkItem: DispatchWorkItem?
    private var fatigueEngine: HumanFatigueEngine?

    init() {
        setupListeners()
    }


    /// Listen for key pressed/released events
    private func setupListeners() {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { (event) in
            if Sauce.shared.key(for: Int(event.keyCode)) == self.activationKey {
                self.keyDown()
            }
        }

        NSEvent.addGlobalMonitorForEvents(matching: [.keyUp]) { event in
            if Sauce.shared.key(for: Int(event.keyCode)) == self.activationKey {
                self.keyUp()
            }
        }
    }

    /// Handles key down event based on selected mode
    private func keyDown() {
        if mode == .toggle {
            toggleClicker()
        } else if mode == .hold {
            startClicker()
        }
    }

    /// Handles key up event based on selected mode
    private func keyUp() {
        if mode == .hold {
            stopClicker()
        } else if mode == .lock {
            toggleLock()
        }
    }

    /// Starts clicker — uses humanise variable-delay scheduling when enabled, fixed Timer otherwise
    private func startClicker() {
        if humaniseEnabled {
            startHumaniseClicker()
        } else if clickerTimer == nil {
            clickerTimer = Timer.scheduledTimer(timeInterval: 1.0 / Double(cps), target: self, selector: #selector(clickerTimerFired), userInfo: nil, repeats: true)
        }
    }

    /// Stops clicker and resets state
    private func stopClicker() {
        // Standard timer
        clickerTimer?.invalidate()
        clickerTimer = nil
        clickCount = 0

        // Humanise
        humaniseWorkItem?.cancel()
        humaniseWorkItem = nil
        sessionStart = nil
        humaniseClickCount = 0
        fatigueEngine = nil
    }

    /// Toggles clicker (when in toggle mode)
    private func toggleClicker() {
        let isRunning = clickerTimer != nil || humaniseWorkItem != nil
        if isRunning {
            stopClicker()
        } else {
            startClicker()
        }
    }

    /// Toggles mouse button lock
    private func toggleLock() {
        // Release buttons to prevent bugs after switching modes
        releaseAllButtons()

        if isLocked {
            postMouseEvent(type:  mouseButton == .right ? .rightMouseUp : .leftMouseUp)
            isLocked = false
        } else {
            postMouseEvent(type: mouseButton == .right ? .rightMouseDown : .leftMouseDown)
            isLocked = true
        }
    }


    // MARK: - Humanise Clicker

    /// Begins a humanise session and schedules the first click
    private func startHumaniseClicker() {
        guard humaniseWorkItem == nil else { return }
        sessionStart = Date()
        humaniseClickCount = 0
        fatigueEngine = HumanFatigueEngine(seed: Double.random(in: 0...100))
        scheduleNextHumaniseClick()
    }

    /// Schedules the next humanise click using a one-shot DispatchWorkItem
    private func scheduleNextHumaniseClick() {
        let elapsed = sessionStart.map { -$0.timeIntervalSinceNow } ?? 0
        let baseMs  = 1000.0 / Double(max(1, cps))

        guard let engine = fatigueEngine else { return }
        let delayMs = engine.nextDelayMs(
            baseMs:          baseMs,
            elapsed:         elapsed,
            clickCount:      humaniseClickCount,
            fatigueEnabled:  fatigueEnabled,
            noiseEnabled:    noiseEnabled,
            collapseEnabled: collapseEnabled
        )

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.humaniseWorkItem != nil else { return }

            // Check click limit before firing
            if self.mode == .toggle && self.useClickLimit && self.humaniseClickCount >= self.clickLimit {
                DispatchQueue.main.async { self.stopClicker() }
                return
            }

            self.performHumaniseClick()
            self.humaniseClickCount += 1

            // Check limit after firing
            if self.mode == .toggle && self.useClickLimit && self.humaniseClickCount >= self.clickLimit {
                DispatchQueue.main.async { self.stopClicker() }
                return
            }

            self.scheduleNextHumaniseClick()
        }

        humaniseWorkItem = workItem
        // Subtract expected hold (~25ms) + dispatch overhead (~8ms) so the
        // total inter-click interval (wait + hold) matches the intended delayMs.
        let scheduledMs = max(5.0, delayMs - 33.0)
        DispatchQueue.global(qos: .userInteractive).asyncAfter(
            deadline: .now() + scheduledMs / 1000.0,
            execute: workItem
        )
    }

    /// Fires a single humanise click with variable hold duration
    private func performHumaniseClick() {
        releaseAllButtons()
        postMouseEvent(type: mouseButton == .right ? .rightMouseDown : .leftMouseDown)

        // Variable press duration: ~25ms ± 8ms (realistic mouse click)
        let holdMs = max(5.0, HumanFatigueEngine.gaussianRandom(mean: 25, sd: 8))
        Thread.sleep(forTimeInterval: holdMs / 1000.0)

        postMouseEvent(type: mouseButton == .right ? .rightMouseUp : .leftMouseUp)
    }


    // MARK: - Standard Timer Clicker

    /// Releases both mouse buttons
    private func releaseAllButtons() {
        postMouseEvent(type: .leftMouseUp)
        postMouseEvent(type: .rightMouseUp)
    }

    /// Clicker timer callback (used for toggle and hold option, to perform clicks at the set cps/interval)
    @objc private func clickerTimerFired(timer: Timer) {
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            if self.mode == .toggle && self.useClickLimit && self.clickCount + 1 > self.clickLimit {
                self.stopClicker()
                return
            }

            // Release buttons to prevent bugs after switching modes
            self.releaseAllButtons()

            self.postMouseEvent(type: self.mouseButton == .right ? .rightMouseDown : .leftMouseDown)
            self.postMouseEvent(type: self.mouseButton == .left ? .leftMouseUp : .leftMouseUp)
            self.clickCount += 1
        }
    }

    /// Sends mouse event based on type and selected mouse button
    /// - Parameters:
    ///     - type: Type of mouse event (e.g.: leftMouseDown, leftMouseUp, ...)
    private func postMouseEvent(type: CGEventType) {
        var mouseLocation = NSEvent.mouseLocation
        mouseLocation.y = NSHeight(NSScreen.screens[0].frame) - mouseLocation.y

        let point = CGPoint(x: mouseLocation.x, y: mouseLocation.y)
        let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: mouseButton)

        event?.post(tap: .cghidEventTap)
    }
}
