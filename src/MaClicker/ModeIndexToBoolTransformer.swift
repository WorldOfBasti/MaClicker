//
//  ModeIndexToBoolTransformer.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 14.11.21.
//  Github: https://github.com/WorldOfBasti
//

import Foundation

@objc(ModeIndexToBoolTransformer)
public final class ModeIndexToBoolTransformer: ValueTransformer {
    // Return true if click is selected
    public override func transformedValue(_ value: Any?) -> Any? {
        let index = value as? Int ?? 0
        if index == 0 {
            return true
        } else {
            return false
        }
    }
}
