//
//  ClickerMode.swift
//  MaClicker
//
//  Created by Bastian Aunkofer on 14.09.24.
//  Github: https://github.com/WorldOfBasti
//

import Foundation

enum ClickerMode: Int {
    case toggle = 0     // Toggle clicker on/off when key is pressed
    case hold = 1       // Only click while key is held down
    case lock = 2       // Lock the mouse button (toggle press/release with key)
}
