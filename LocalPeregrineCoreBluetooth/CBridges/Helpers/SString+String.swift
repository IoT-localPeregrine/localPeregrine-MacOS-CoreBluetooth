//
//  SString+String.swift
//  LocalPeregrineCoreBluetooth
//
//  Created by Булат Мусин on 21.06.2023.
//

import Foundation

extension SString {
    func toString() -> String {
        return String(cString: self.val.unsafelyUnwrapped)
    }
}

extension String {
    func toSString() -> SString {
        guard let cchar = cString(using: .utf8) else {
            return SString()
        }
        let value = UnsafeMutablePointer<CChar>.allocate(capacity: self.count + 1)
        memcpy(value, cchar, self.count + 1)
        return SString(val: value, cnt: self.count)
    }
}
