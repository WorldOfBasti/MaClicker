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

enum ClickIntervalUnit: Int {
    case milliseconds = 0
    case seconds = 1
    case minutes = 2
    case hours = 3

    var localizationKey: String {
        switch self {
        case .milliseconds: return "interval_unit_ms"
        case .seconds: return "interval_unit_s"
        case .minutes: return "interval_unit_min"
        case .hours: return "interval_unit_h"
        }
    }

    func seconds(for value: Double) -> TimeInterval {
        switch self {
        case .milliseconds: return value / 1_000.0
        case .seconds: return value
        case .minutes: return value * 60.0
        case .hours: return value * 3_600.0
        }
    }
}

final class AutoClicker {
    private var activationKey: Key?        { Key(QWERTYKeyCode: UserDefaults.standard.integer(forKey: "ActivationKey")) }
    private var mode: ClickerMode          { ClickerMode(rawValue: UserDefaults.standard.integer(forKey: "ModeIndex")) ?? .toggle }
    private var useClickLimit: Bool        { UserDefaults.standard.bool(forKey: "LimitEnabled") }
    private var clickLimit: Int            { UserDefaults.standard.integer(forKey: "ClickLimit") }
    private var mouseButton: CGMouseButton { UserDefaults.standard.integer(forKey: "MouseButtonIndex") == 1 ? .right : .left }
    private var intervalValue: Double      { max(UserDefaults.standard.double(forKey: "ClickIntervalValue"), 1.0) }
    private var intervalUnit: ClickIntervalUnit {
        ClickIntervalUnit(rawValue: UserDefaults.standard.integer(forKey: "ClickIntervalUnit")) ?? .milliseconds
    }
    
    private var clickerTimer: Timer?
    private var clickCount = 0
    private var isClicking = false
    private var isLocked = false
    
    var isActive: Bool {
        isClicking || isLocked
    }
    
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
    
    /// Starts clicker
    private func startClicker() {
        guard !isClicking else {
            return
        }

        isClicking = true
        scheduleNextClick()
        notifyStatusChanged()
    }

    /// Schedules one click using the currently selected interval.
    private func scheduleNextClick() {
        guard isClicking else {
            return
        }

        let nextInterval = max(0.001, intervalUnit.seconds(for: intervalValue))
        clickerTimer = Timer.scheduledTimer(timeInterval: nextInterval,
                                            target: self,
                                            selector: #selector(clickerTimerFired),
                                            userInfo: nil,
                                            repeats: false)
    }
    
    /// Stops clicker and resets limit click counter
    private func stopClicker() {
        isClicking = false
        clickerTimer?.invalidate()
        clickerTimer = nil
        clickCount = 0
        notifyStatusChanged()
    }
    
    /// Toggles clicker (when in toggle mode)
    private func toggleClicker() {
        if isClicking {
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
        notifyStatusChanged()
    }
    
    
    /// Releases both mouse buttons
    private func releaseAllButtons() {
        postMouseEvent(type: .leftMouseUp)
        postMouseEvent(type: .rightMouseUp)
    }
    
    /// Clicker timer callback (used for toggle and hold option, to perform clicks at the set interval)
    @objc private func clickerTimerFired(timer: Timer) {
        clickerTimer = nil

        guard isClicking else {
            return
        }

        if mode == .toggle && useClickLimit && clickCount + 1 > clickLimit {
            stopClicker()
            return
        }

        // Release buttons to prevent bugs after switching modes
        releaseAllButtons()

        postMouseEvent(type: mouseButton == .right ? .rightMouseDown : .leftMouseDown)
        postMouseEvent(type: mouseButton == .left ? .leftMouseUp : .leftMouseUp)
        clickCount += 1

        scheduleNextClick()
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
    
    /// Posts notification when clicker status changes
    private func notifyStatusChanged() {
        NotificationCenter.default.post(name: .clickerStatusChanged, object: nil, userInfo: ["isActive": isActive])
    }
}
extension Notification.Name {
    static let clickerStatusChanged = Notification.Name("clickerStatusChanged")
}
