//
//  AllowLimitTransformer.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 13.09.24.
//  Github: https://github.com/WorldOfBasti
//

import Foundation

@objc(AllowLimitTransformer)
public final class AllowLimitTransformer: ValueTransformer {
    // Only when Toggle is selected
    public override func transformedValue(_ value: Any?) -> Any? {
        let index = value as? Int ?? 0
        return index == 0
    }
}
