//
//  GetKeyPopoverViewController.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 12.11.21.
//  Github: https://github.com/WorldOfBasti
//

import Foundation
import AppKit

protocol GetKeyPopoverViewControllerDelegate {
    func keySelected(key: uint16)
}

class GetKeyPopoverViewController: NSViewController {
    var delegate: GetKeyPopoverViewControllerDelegate?
    var monitor: Any?
        
    override func viewWillAppear() {
        super.viewWillAppear()
                
        // Add handler for key events
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown], handler: self.handler)
    }
    
    lazy var handler: (NSEvent) -> NSEvent? = { (event) in
        // Notify delegate that key was pressed
        self.delegate?.keySelected(key: event.keyCode)
        return nil
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        // Remove handler for key events
        NSEvent.removeMonitor(monitor!)
    }
}
