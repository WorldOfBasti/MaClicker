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

    private var intervalUnitPopup: NSPopUpButton!
    private var intervalJitterCheckbox: NSButton!
    
    var keyPopover: NSPopover!
    var updaterController: SPUStandardUpdaterController!
    
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

        // The storyboard still contains the old CPS bindings. Keep its layout and
        // enabled-state binding, but manage interval value/unit ourselves.
        setupIntervalControls()
        
        // Set up click limit stepper
        limitStepper.increment = 10
        limitStepper.maxValue = Double.infinity

        localizeInterface()
        
        // Check for accessibility permission
        if !AXIsProcessTrusted() {
            let result = shouldOpenSystemSettings()
            
            if result, let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
        
        // Check for updates
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    private func setupIntervalControls() {
        cpsTextField.unbind(.value)
        cpsStepper.unbind(.value)

        let defaults = UserDefaults.standard
        let intervalValue = max(defaults.integer(forKey: "ClickIntervalValue"), 1)
        let unit = ClickIntervalUnit(rawValue: defaults.integer(forKey: "ClickIntervalUnit")) ?? .milliseconds

        cpsTextField.integerValue = intervalValue
        cpsStepper.integerValue = intervalValue
        cpsStepper.minValue = 1
        cpsStepper.maxValue = Double.infinity
        cpsStepper.increment = 1
        cpsStepper.target = self
        cpsStepper.action = #selector(intervalStepperChanged(_:))

        intervalUnitPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        intervalUnitPopup.translatesAutoresizingMaskIntoConstraints = false
        intervalUnitPopup.addItems(withTitles: [
            localized("interval_unit_ms"),
            localized("interval_unit_s"),
            localized("interval_unit_min"),
            localized("interval_unit_h")
        ])
        intervalUnitPopup.selectItem(at: unit.rawValue)
        intervalUnitPopup.target = self
        intervalUnitPopup.action = #selector(intervalUnitChanged(_:))
        view.addSubview(intervalUnitPopup)

        intervalJitterCheckbox = NSButton(checkboxWithTitle: localized("interval_jitter"),
                                          target: self,
                                          action: #selector(intervalJitterChanged(_:)))
        intervalJitterCheckbox.translatesAutoresizingMaskIntoConstraints = false
        intervalJitterCheckbox.state = defaults.bool(forKey: "IntervalJitterEnabled") ? .on : .off
        intervalJitterCheckbox.toolTip = localized("interval_jitter_tooltip")
        view.addSubview(intervalJitterCheckbox)

        // The original storyboard has only one row for the click interval.
        // Insert a dedicated row for timing variance and keep the footer in place.
        let extraRowHeight: CGFloat = 26
        expandLayoutForJitterRow(by: extraRowHeight)

        if let oldSpacingConstraint = view.constraints.first(where: {
            ($0.firstItem as? NSStepper) === cpsStepper &&
            ($0.secondItem as? NSTextField) === cpsTextField &&
            $0.firstAttribute == .leading &&
            $0.secondAttribute == .trailing
        }) {
            oldSpacingConstraint.isActive = false
        }

        // Do not position the interval field relative to the localized label width.
        // All controls use a fixed column so longer translations cannot overlap them.
        if let fieldLeadingConstraint = view.constraints.first(where: {
            ($0.firstItem as? NSTextField) === cpsTextField &&
            $0.firstAttribute == .leading
        }) {
            fieldLeadingConstraint.isActive = false
        }

        NSLayoutConstraint.activate([
            cpsTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 165),
            cpsTextField.widthAnchor.constraint(equalToConstant: 70),
            intervalUnitPopup.leadingAnchor.constraint(equalTo: cpsTextField.trailingAnchor, constant: 6),
            intervalUnitPopup.trailingAnchor.constraint(equalTo: cpsStepper.leadingAnchor, constant: -6),
            intervalUnitPopup.centerYAnchor.constraint(equalTo: cpsTextField.centerYAnchor),
            intervalJitterCheckbox.leadingAnchor.constraint(equalTo: cpsTextField.leadingAnchor),
            intervalJitterCheckbox.centerYAnchor.constraint(equalTo: cpsTextField.centerYAnchor,
                                                             constant: -extraRowHeight)
        ])
    }

    private func expandLayoutForJitterRow(by height: CGFloat) {
        let clickLimitLabel = view.subviews
            .compactMap { $0 as? NSTextField }
            .first { ["Click limit:", "Klick Limit:"].contains($0.stringValue) }
        let clickLimitToggle = view.subviews
            .compactMap { $0 as? NSButton }
            .first { ["Enable", "Aktiviert"].contains($0.title) }

        let viewsToMove = [limitTextField as NSView?, limitStepper as NSView?, clickLimitLabel, clickLimitToggle]
            .compactMap { $0 }

        for constraint in view.constraints where constraint.firstAttribute == .top {
            guard let firstView = constraint.firstItem as? NSView,
                  viewsToMove.contains(where: { $0 === firstView }) else {
                continue
            }
            constraint.constant += height
        }

        var frame = view.frame
        frame.size.height += height
        view.frame = frame
        preferredContentSize = frame.size
    }

    @objc private func intervalStepperChanged(_ sender: NSStepper) {
        let value = max(sender.integerValue, 1)
        sender.integerValue = value
        cpsTextField.integerValue = value
        UserDefaults.standard.set(value, forKey: "ClickIntervalValue")
    }

    @objc private func intervalUnitChanged(_ sender: NSPopUpButton) {
        UserDefaults.standard.set(sender.indexOfSelectedItem, forKey: "ClickIntervalUnit")
    }

    @objc private func intervalJitterChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "IntervalJitterEnabled")
    }

    private func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    private func localizeInterface() {
        localize(view: view)

        if let popoverView = keyPopover.contentViewController?.view {
            localize(view: popoverView)
        }
    }

    private func localize(view rootView: NSView) {
        let titleKeys: [String: String] = [
            "Mode:": "ui_mode",
            "Modus:": "ui_mode",
            "Activation key:": "ui_activation_key",
            "Aktivierungstaste:": "ui_activation_key",
            "Mouse button:": "ui_mouse_button",
            "Maustaste:": "ui_mouse_button",
            "Clicks per second:": "interval_label",
            "Klicks pro Sekunde:": "interval_label",
            "Click limit:": "ui_click_limit",
            "Klick Limit:": "ui_click_limit",
            "Select": "ui_select",
            "Auswählen": "ui_select",
            "Enable": "ui_enable",
            "Aktiviert": "ui_enable",
            "Quit": "ui_quit",
            "Beenden": "ui_quit",
            "Left mouse button": "ui_left_mouse_button",
            "Linke Maustaste": "ui_left_mouse_button",
            "Right mouse button": "ui_right_mouse_button",
            "Rechte Maustaste": "ui_right_mouse_button",
            "Press key.\nPress ESC to cancel.": "ui_press_key",
            "Taste drücken.\nESC um abzubrechen.": "ui_press_key"
        ]

        let segmentKeys: [String: String] = [
            "Toggle": "ui_mode_toggle",
            "Umschalten": "ui_mode_toggle",
            "Hold": "ui_mode_hold",
            "Halten": "ui_mode_hold",
            "Lock": "ui_mode_lock",
            "Einrasten": "ui_mode_lock"
        ]

        for subview in rootView.subviews {
            if let popup = subview as? NSPopUpButton {
                for item in popup.itemArray {
                    if let key = titleKeys[item.title] {
                        item.title = localized(key)
                    }
                }
            } else if let segmentedControl = subview as? NSSegmentedControl {
                for index in 0..<segmentedControl.segmentCount {
                    if let title = segmentedControl.label(forSegment: index),
                       let key = segmentKeys[title] {
                        segmentedControl.setLabel(localized(key), forSegment: index)
                    }
                }
            } else if let button = subview as? NSButton {
                if let key = titleKeys[button.title] {
                    button.title = localized(key)
                }
            } else if let textField = subview as? NSTextField {
                if let key = titleKeys[textField.stringValue] {
                    textField.stringValue = localized(key)
                }
            }

            localize(view: subview)
        }
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
            // Click interval
        case cpsTextField.identifier:
            guard let value = Int(textField.stringValue), value > 0 else {
                return
            }

            cpsStepper.integerValue = value
            UserDefaults.standard.set(value, forKey: "ClickIntervalValue")
            
            // Click limit
        case limitTextField.identifier:
            let value = Int(textField.stringValue) ?? 0
            UserDefaults.standard.set(value, forKey: "ClickLimit")
            
        default:
            break
        }
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
              textField.identifier == cpsTextField.identifier else {
            return
        }

        if Int(textField.stringValue) == nil || textField.integerValue < 1 {
            let value = max(UserDefaults.standard.integer(forKey: "ClickIntervalValue"), 1)
            textField.integerValue = value
            cpsStepper.integerValue = value
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
