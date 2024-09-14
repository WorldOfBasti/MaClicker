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
    // Return character value of keycode
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let qwertyKeyCode = value as? Int else {
            return ""
        }
        
        guard let key = Key(QWERTYKeyCode: qwertyKeyCode) else {
            return ""
        }
        
        let keyCode = Sauce.shared.keyCode(for: key)
        return Sauce.shared.character(for: Int(keyCode), cocoaModifiers: [])
    }
}
