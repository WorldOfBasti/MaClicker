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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Set the default value of enabled limit to false to prevent some issues at first startup
        UserDefaults.standard.register(defaults: ["LimitEnabled" : false])
        
        // Set up menubar icon
        let icon = NSImage(named: "MenuBarIcon")
        icon?.isTemplate = true
        
        statusItem.button?.image = icon
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopOver)
        
        let storyBoard = NSStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyBoard.instantiateController(withIdentifier: "ViewController") as? ViewController else { fatalError("Unable to find ViewController!") }
        popover.contentViewController = viewController
        popover.behavior = .transient
        
        // Ask for accessibillity permissions
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary?)
        
        // Show Popover for first time
        togglePopOver()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    ///
    /// Show/hide popover
    ///
    @objc func togglePopOver() {
        guard let button = statusItem.button else { fatalError("Could not find status item button!") }
        
        if popover.isShown {
            popover.performClose(self)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        }
    }
}
