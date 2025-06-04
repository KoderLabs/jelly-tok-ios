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
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        let decoder = JSONDecoder()
        do {
            let loaded = try decoder.decode(T.self, from: data)
            return loaded
        } catch {
            return nil
        }
    }
}
