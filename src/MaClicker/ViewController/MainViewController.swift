//
//  MainViewController.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 07.11.21.
//  Github: https://github.com/WorldOfBasti
//

import Cocoa
import Sauce
import Sparkle

class MainViewController: NSViewController {
    @IBOutlet weak var cpsTextField: NSTextField!
    @IBOutlet weak var limitTextField: NSTextField!
    @IBOutlet weak var cpsStepper: NSStepper!
    @IBOutlet weak var limitStepper: NSStepper!
    @IBOutlet weak var activationKeyLabel: NSTextField!
    
    var keyPopover: NSPopover!
    var updaterController: SPUStandardUpdaterController!
    var autoClicker: AutoClicker?
    
    /// View did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up key selection popover
        let vc: KeyPopoverViewController = storyboard?.instantiateController(withIdentifier: "GetKeyPopoverViewController") as! KeyPopoverViewController
        vc.delegate = self
        keyPopover = NSPopover()
        keyPopover.behavior = .transient
        keyPopover.contentViewController = vc
        
        // Set up text fields (and only allow integer inputs)
        let forceIntegerFormatter = ForceIntegerFormatter()
        cpsTextField.formatter = forceIntegerFormatter
        limitTextField.formatter = forceIntegerFormatter
        
        // Set up steppers
        cpsStepper.increment = 5
        cpsStepper.maxValue = 100
        limitStepper.increment = 10
        limitStepper.maxValue = Double.infinity
        
        // Update activation key display
        updateActivationKeyDisplay()
        
        // Check for accessibility permission
        if !AXIsProcessTrusted() {
            let result = shouldOpenSystemSettings()
            
            if result, let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
        
        // Check for updates
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        autoClicker = AutoClicker()
    }
    
    
    /// Update the activation key label with the current key combination
    private func updateActivationKeyDisplay() {
        let qwertyKeyCode = UserDefaults.standard.integer(forKey: "ActivationKey")
        let modifiersRaw = UserDefaults.standard.integer(forKey: "ActivationModifiers")
        
        // If no key is set yet (0 is default), show "None"
        guard qwertyKeyCode != 0 else {
            activationKeyLabel?.stringValue = "None"
            return
        }
        
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(modifiersRaw))
        
        // Get the key character
        guard let key = Key(QWERTYKeyCode: qwertyKeyCode) else {
            activationKeyLabel?.stringValue = "Unknown"
            return
        }
        
        let keyCode = Sauce.shared.keyCode(for: key)
        let character = Sauce.shared.character(for: Int(keyCode), cocoaModifiers: []) ?? "?"
        
        // Build the display string with modifiers
        let modifierString = modifierFlagsToString(modifiers)
        let displayString = modifierString.isEmpty ? character : "\(modifierString)\(character)"
        
        // Force unbind to ensure programmatic updates work
        activationKeyLabel?.unbind(.value)
        activationKeyLabel?.stringValue = displayString.uppercased()
    }
    
    
    /// Ask if accessibility settings should open
    /// - Returns: Boolean indicating if user wants to open accessibility settings
    private func shouldOpenSystemSettings() -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = NSLocalizedString("accessibility_alert_message", comment: "")
        alert.informativeText = NSLocalizedString("accessibility_alert_informative_text", comment: "")
        alert.addButton(withTitle: NSLocalizedString("accessibility_alert_open_settings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("accessibility_alert_ok", comment: ""))
        
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    
    /// Select activation key
    @IBAction func selectButtonClicked(_ sender: Any) {
        guard let button = sender as? NSButton else {
            return
        }
        
        keyPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minX)
    }
    
    /// Check for updates
    @IBAction func updateButtonClicked(_ sender: Any) {
        updaterController?.checkForUpdates(self)
    }
    
    /// Quit application
    @IBAction func quitButtonClicked(_ sender: Any) {
        NSApplication.shared.terminate(sender)
    }
}


extension MainViewController: NSTextFieldDelegate {
    /// Text in text field was changed
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            return
        }
        
        switch (textField.identifier) {
            // CPS
        case cpsTextField.identifier:
            // Only allow 100 cps
            var value = Int(textField.stringValue) ?? 0
            if value > 100 {
                textField.stringValue = "100"
                value = 100
            }
            
            UserDefaults.standard.set(value, forKey: "ClicksPerSecond")
            
            // Click limit
        case limitTextField.identifier:
            let value = Int(textField.stringValue) ?? 0
            UserDefaults.standard.set(value, forKey: "ClickLimit")
            
        default:
            break
        }
    }
}


extension MainViewController: KeyPopoverViewControllerDelegate {
    /// Activation key in Popover was selected
    func keySelected(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        if keyCode != Sauce.shared.keyCode(for: .escape) {      // Don't save Escape key
            let key = Sauce.shared.key(for: Int(keyCode))
            
            // Save modifier flags first (only relevant ones: command, option, shift, control)
            let relevantModifiers: NSEvent.ModifierFlags = [.command, .option, .shift, .control]
            let savedModifiers = modifiers.intersection(relevantModifiers)
            UserDefaults.standard.set(Int(savedModifiers.rawValue), forKey: "ActivationModifiers")
            
            // Save key code after modifiers so the transformer can read both
            UserDefaults.standard.set(key?.QWERTYKeyCode ?? keyCode, forKey: "ActivationKey")
            
            // Update the display
            updateActivationKeyDisplay()
        }
        
        keyPopover.performClose(self)
    }
    
    /// Converts modifier flags to a human-readable string
    private func modifierFlagsToString(_ modifiers: NSEvent.ModifierFlags) -> String {
        var components: [String] = []
        
        if modifiers.contains(.control) {
            components.append("⌃")
        }
        if modifiers.contains(.option) {
            components.append("⌥")
        }
        if modifiers.contains(.shift) {
            components.append("⇧")
        }
        if modifiers.contains(.command) {
            components.append("⌘")
        }
        
        return components.joined()
    }
}
