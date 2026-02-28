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
    // Return character value of keycode with modifiers
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let qwertyKeyCode = value as? Int else {
            return ""
        }
        
        guard qwertyKeyCode != 0 else {
            return "None"
        }
        
        guard let key = Key(QWERTYKeyCode: qwertyKeyCode) else {
            return "Unknown"
        }
        
        let keyCode = Sauce.shared.keyCode(for: key)
        let character = Sauce.shared.character(for: Int(keyCode), cocoaModifiers: []) ?? "?"
        
        // Get modifiers from UserDefaults
        let modifiersRaw = UserDefaults.standard.integer(forKey: "ActivationModifiers")
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(modifiersRaw))
        
        // Build modifier string
        var modifierString = ""
        if modifiers.contains(.control) {
            modifierString += "⌃"
        }
        if modifiers.contains(.option) {
            modifierString += "⌥"
        }
        if modifiers.contains(.shift) {
            modifierString += "⇧"
        }
        if modifiers.contains(.command) {
            modifierString += "⌘"
        }
        
        let displayString = modifierString.isEmpty ? character : "\(modifierString)\(character)"
        return displayString.uppercased()
    }
}
