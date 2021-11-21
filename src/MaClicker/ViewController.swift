//
//  ViewController.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 07.11.21.
//  Github: https://github.com/WorldOfBasti
//

import Cocoa
import Sauce

class ViewController: NSViewController, NSTextFieldDelegate, GetKeyPopoverViewControllerDelegate {
    @IBOutlet weak var cpsTextField: NSTextField!
    @IBOutlet weak var limitTextField: NSTextField!
    @IBOutlet weak var cpsStepper: NSStepper!
    @IBOutlet weak var limitStepper: NSStepper!
    
    var keyPopover: NSPopover!
    var clickerTimer: Timer!
    var isHoldActive: Bool = false
    var currentLoop: Int = 0
    
    ///
    /// View did load
    ///
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up popover
        let vc: GetKeyPopoverViewController = storyboard?.instantiateController(withIdentifier: "GetKeyPopoverViewController") as! GetKeyPopoverViewController
        vc.delegate = self
        keyPopover = NSPopover()
        keyPopover.behavior = .transient
        keyPopover.contentViewController = vc
        
        // Set up text fields
        let onlyIntegerValueFormatter = OnlyIntegerValueFormatter()
        cpsTextField.formatter = onlyIntegerValueFormatter
        limitTextField.formatter = onlyIntegerValueFormatter
        
        
        // Set up stepper
        cpsStepper.increment = 5
        cpsStepper.maxValue = 100
        limitStepper.increment = 10
        limitStepper.maxValue = Double.infinity
            
        // Listen for key pressed event
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { (event) in
            let hotKey: Int = UserDefaults.standard.integer(forKey: "HotKey")
            
            if event.keyCode == hotKey {
                self.toggleMouse()
            }
        }
    }
    
    
    
    ///
    /// Select key button was clicked
    ///
    @IBAction func selectButtonClicked(_ sender: Any) {
        let button = sender as! NSButton
        keyPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minX)
    }
    
    ///
    /// Key in GetKey Popover was selected
    ///
    func keySelected(key: uint16) {
        // Don't save Escape key
        if key != 53 {
            UserDefaults.standard.set(key, forKey: "HotKey")
        }
        keyPopover.performClose(self)
    }
    
    ///
    /// Text in text field was changed
    ///
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        if textField.identifier == cpsTextField.identifier {
            // Only allow 100 cps
            if Int(textField.stringValue) ?? 0 > 100 {
                textField.stringValue = "100"
            }
            
            // Save current cps settings
            UserDefaults.standard.set(textField.stringValue, forKey: "CPS")
        } else {
            // Save current limit settings
            UserDefaults.standard.set(textField.stringValue, forKey: "Limit")
        }
    }
    
    ///
    /// Toggle autoclicker
    ///
    private func toggleMouse() {
        if UserDefaults.standard.integer(forKey: "ModeIndex") == 0 {
            if clickerTimer == nil {
                // Timer is off, start timerrr
                clickerTimer = Timer.scheduledTimer(withTimeInterval: 1.00/(Double(UserDefaults.standard.string(forKey: "CPS") ?? "1.00") ?? 1.00), repeats: true) {
                    timer in self.backgroundTimer(timer: timer)
                }
            } else {
                // Timer is on, stop timer
                clickerTimer.invalidate()
                clickerTimer = nil
                currentLoop = 0
            }
        } else {
            // Get current mouse location
            var mouseLoc = NSEvent.mouseLocation
            mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y
            let point = CGPoint(x: mouseLoc.x, y: mouseLoc.y)
                        
            var mouseDown: CGEvent!
            var mouseUp: CGEvent!
            
            if !isHoldActive {
                // Hold mouse button
                if UserDefaults.standard.integer(forKey: "MouseButtonIndex") == 1 {
                    // Use right mouse button
                    mouseDown = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: point, mouseButton: .right)
                    mouseDown?.post(tap: .cghidEventTap)
                } else {
                    // Use left mouse button
                    mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)
                    mouseDown?.post(tap: .cghidEventTap)
                }
                
                isHoldActive = true
            } else {
                // Release mouse button
                if UserDefaults.standard.integer(forKey: "MouseButtonIndex") == 1 {
                    // Use right mouse button
                    mouseUp = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: point, mouseButton: .right)
                    mouseUp?.post(tap: .cghidEventTap)
                } else {
                    // Use left mouse button
                    mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)
                    mouseUp?.post(tap: .cghidEventTap)
                }
                
                isHoldActive = false
            }
        }
    }
    
    ///
    /// Clicker background timer
    ///
    private func backgroundTimer(timer: Timer) {
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            // Convert limit to integer
            let limitValue = Int(UserDefaults.standard.string(forKey: "Limit") ?? "0") ?? 0
            
            // Check if limit is enabled
            if UserDefaults.standard.bool(forKey: "LimitEnabled") && limitValue != 0 {
                // Check if the limit has been exceeded
                if self.currentLoop + 1 > limitValue {
                    // Stop timer, etc.
                    timer.invalidate()
                    self.clickerTimer = nil
                    self.currentLoop = 0
                    return
                }
                self.currentLoop += 1
            }
            
            // Get current mouse location
            var mouseLoc = NSEvent.mouseLocation
            mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y
            let point = CGPoint(x: mouseLoc.x, y: mouseLoc.y)
            
            var mouseDown: CGEvent!
            var mouseUp: CGEvent!
            if UserDefaults.standard.integer(forKey: "MouseButtonIndex") == 1 {
                // Use right mouse button
                mouseDown = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: point, mouseButton: .right)
                mouseUp = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: point, mouseButton: .right)
            } else {
                // Use left mouse button
                mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)
                mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)
            }

            //Press and release mouse button
            mouseDown.post(tap: .cghidEventTap)
            mouseUp.post(tap: .cghidEventTap)
        }
    }
    
    ///
    /// Quit Application
    ///
    @IBAction func quitButtonClicked(_ sender: Any) {
        NSApplication.shared.terminate(sender)
    }
}
