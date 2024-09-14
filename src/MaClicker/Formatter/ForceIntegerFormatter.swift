//
//  ForceIntegerFormatter.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 15.11.21.
//  Github: https://github.com/WorldOfBasti
//

import Foundation

class ForceIntegerFormatter: NumberFormatter {
    // Only allow integer numbers
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        return partialString.isEmpty || Int(partialString) != nil
    }
}
