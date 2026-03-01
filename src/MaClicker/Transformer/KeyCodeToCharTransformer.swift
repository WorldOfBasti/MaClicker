//
//  KeyCodeToCharTransformer.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 12.11.21.
//  Github: https://github.com/WorldOfBasti
//

import Foundation
import AppKit
import Sauce

@objc(KeyCodeToCharTransformer)
public final class KeyCodeToCharTransformer: ValueTransformer {
    // Return character value of keycode with modifier symbols
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let qwertyKeyCode = value as? Int else {
            return ""
        }
        
        guard let key = Key(QWERTYKeyCode: qwertyKeyCode) else {
            return ""
        }
        
        let keyCode = Sauce.shared.keyCode(for: key)
        let character = Sauce.shared.character(for: Int(keyCode), cocoaModifiers: []) ?? ""
        
        // Get saved modifiers
        let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(UserDefaults.standard.integer(forKey: "ActivationModifiers")))
        let modifierString = self.modifierString(from: modifierFlags)
        
        return modifierString + character.uppercased()
    }
    
    /// Convert modifier flags to macOS symbol string
    private func modifierString(from modifiers: NSEvent.ModifierFlags) -> String {
        var result = ""
        
        if modifiers.contains(.control) {
            result += "⌃"
        }
        if modifiers.contains(.option) {
            result += "⌥"
        }
        if modifiers.contains(.shift) {
            result += "⇧"
        }
        if modifiers.contains(.command) {
            result += "⌘"
        }
        
        return result
    }
}
