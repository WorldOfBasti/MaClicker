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
    func keySelected(keyCode: uint16) {
        if keyCode != Sauce.shared.keyCode(for: .escape) {      // Don't save Escape key
            let key = Sauce.shared.key(for: Int(keyCode))
            UserDefaults.standard.set(key?.QWERTYKeyCode ?? keyCode, forKey: "ActivationKey")
        }
        
        keyPopover.performClose(self)
    }
}
