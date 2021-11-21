//
//  KeyCodeToKeyTransformer.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 12.11.21.
//  Github: https://github.com/WorldOfBasti
//

import Foundation
import AppKit
import Sauce

@objc(KeyCodeToKeyTransformer)
public final class KeyCodeToKeyTransformer: ValueTransformer {
    // Return string value of keycode
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let keyCode = value as? Int else { return "" }
        let keyChar = Sauce.shared.character(for: keyCode, cocoaModifiers: [])
        
        return keyChar
    }
}
