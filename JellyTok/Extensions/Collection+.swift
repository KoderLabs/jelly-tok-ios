//
//  Collection+.swift
//  JellyTok
//
//  Created by Faique Ali on 03/06/2025.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
