//
//  KeyPopoverViewController.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 12.11.21.
//  Github: https://github.com/WorldOfBasti
//

import Foundation
import AppKit

protocol KeyPopoverViewControllerDelegate {
    func keySelected(keyCode: uint16, modifiers: NSEvent.ModifierFlags)
}

class KeyPopoverViewController: NSViewController {
    var delegate: KeyPopoverViewControllerDelegate?
    var monitor: Any?
        
    override func viewWillAppear() {
        super.viewWillAppear()
                
        // Add handler for key events
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown], handler: self.handler)
    }
    
    lazy var handler: (NSEvent) -> NSEvent? = { (event) in
        let relevantModifiers = event.modifierFlags.intersection([.command, .option, .shift, .control])
        self.delegate?.keySelected(keyCode: event.keyCode, modifiers: relevantModifiers)
        return nil
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        // Remove handler for key events
        NSEvent.removeMonitor(monitor!)
    }
}
