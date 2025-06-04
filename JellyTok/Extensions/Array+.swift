//
//  Array+.swift
//  JellyTok
//
//  Created by Faique Ali on 04/06/2025.
//

extension Array {
    func get(at index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
