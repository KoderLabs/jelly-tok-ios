//
//  Bundle+.swift
//  JellyTok
//
//  Created by Faique Ali on 29/05/2025.
//

import Foundation

extension Bundle {
    func decode<T: Decodable>(_ file: String) -> T? {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            debugPrint("📁 Could not find \(file) in bundle.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            debugPrint("Error decoding \(file): \(error)")
            return nil
        }
    }
}

