//
//  AllowCPSTransformer.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 14.11.21.
//  Github: https://github.com/WorldOfBasti
//

import Foundation

@objc(AllowCPSTransformer)
public final class AllowCPSTransformer: ValueTransformer {
    // Only when Toggle or Hold is selected
    public override func transformedValue(_ value: Any?) -> Any? {
        let index = value as? Int ?? 0
        switch index {
        case 0, 1:
            return true
            
        default:
            return false
        }
    }
}
