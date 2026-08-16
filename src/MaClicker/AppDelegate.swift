//
//  AppDelegate.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 07.11.21.
//  Github: https://github.com/WorldOfBasti
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let popover = NSPopover()
    var autoClicker: AutoClicker?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let defaults = UserDefaults.standard

        // Migrate the old CPS setting once. 10 CPS, for example, becomes 100 ms.
        if defaults.object(forKey: "ClickIntervalValue") == nil {
            let oldCPS = max((defaults.object(forKey: "ClicksPerSecond") as? Int) ?? 10, 1)
            let intervalMilliseconds = max(Int((1_000.0 / Double(oldCPS)).rounded()), 1)
            defaults.set(intervalMilliseconds, forKey: "ClickIntervalValue")
            defaults.set(ClickIntervalUnit.milliseconds.rawValue, forKey: "ClickIntervalUnit")
        }

        // Set default UserDefaults
        defaults.register(defaults: [
            "ClicksPerSecond": 10,
            "ClickIntervalValue": 100,
            "ClickIntervalUnit": ClickIntervalUnit.milliseconds.rawValue,
            "IntervalJitterEnabled": false,
            "LimitEnabled" : false,
            "ClickLimit": 100
        ])
        
        // Set up menubar icon
        let icon = NSImage(named: "MenubarIcon")
        icon?.size = NSSize(width: 16, height: 16)
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopOver)
        
        let storyBoard = NSStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyBoard.instantiateController(withIdentifier: "ViewController") as? MainViewController else { fatalError("Unable to find ViewController!") }
        popover.contentViewController = viewController
        popover.behavior = .transient
        
        // Initialize AutoClicker
        autoClicker = AutoClicker()
        
        // Listen for clicker status changes
        NotificationCenter.default.addObserver(self, selector: #selector(clickerStatusChanged), name: .clickerStatusChanged, object: nil)
        
        // Ask for accessibillity permissions
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary?)
        
        // Show Popover for first time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {     // Wait to prevent popover appears at wrong position
            self.togglePopOver()
        }
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    /// Show/hide popover
    @objc func togglePopOver() {
        guard let button = statusItem.button else { fatalError("Could not find status item button!") }
        
        if popover.isShown {
            popover.performClose(self)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        }
    }
    
    /// Updates the menubar icon color based on clicker status
    @objc func clickerStatusChanged(notification: Notification) {
        guard let isActive = notification.userInfo?["isActive"] as? Bool else { return }
        
        DispatchQueue.main.async {
            if isActive {
                // Create a green filled version of the icon
                if let originalIcon = NSImage(named: "MenubarIcon") {
                    let greenIcon = self.createTintedImage(from: originalIcon, tintColor: .systemGreen)
                    greenIcon.size = NSSize(width: 16, height: 16)
                    self.statusItem.button?.image = greenIcon
                }
            } else {
                // Reset to default template icon
                let icon = NSImage(named: "MenubarIcon")
                icon?.size = NSSize(width: 16, height: 16)
                icon?.isTemplate = true
                self.statusItem.button?.image = icon
            }
        }
    }
    
    /// Creates a tinted version of an image
    private func createTintedImage(from image: NSImage, tintColor: NSColor) -> NSImage {
        let tintedImage = NSImage(size: image.size)
        tintedImage.lockFocus()
        
        tintColor.set()
        
        let imageRect = NSRect(origin: .zero, size: image.size)
        image.draw(in: imageRect, from: imageRect, operation: .sourceOver, fraction: 1.0)
        imageRect.fill(using: .sourceAtop)
        
        tintedImage.unlockFocus()
        return tintedImage
    }
}
