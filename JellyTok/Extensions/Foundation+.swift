//
//  Foundation+.swift
//  JellyTok
//
//  Created by Faique Ali on 30/05/2025.
//

import Foundation

public func debugPrint(_ message: String) {
    #if DEBUG
    print("[Debug]: \(message)")
    #endif
}
