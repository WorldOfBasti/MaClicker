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
    
    private var clickerTimer: Timer?
    private var clickCount = 0
    private var isLocked = false
    
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
        if clickerTimer == nil {
            clickerTimer = Timer.scheduledTimer(timeInterval: 1.0 / Double(cps), target: self, selector: #selector(clickerTimerFired), userInfo: nil, repeats: true)
        }
    }
    
    /// Stops clicker and resets limit click counter
    private func stopClicker() {
        clickerTimer?.invalidate()
        clickerTimer = nil
        clickCount = 0
    }
    
    /// Toggles clicker (when in toggle mode)
    private func toggleClicker() {
        if clickerTimer == nil {
            startClicker()
        } else {
            stopClicker()
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
