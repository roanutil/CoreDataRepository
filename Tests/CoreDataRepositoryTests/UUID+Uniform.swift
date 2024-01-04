// UUID+Uniform.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import Foundation

extension UUID {
    /// BA7097EA-70FD-4595-9268-6D415A222C7B
    init(uniform character: Character) {
        let x8 = String(repeating: character, count: 8)
        let x4 = String(repeating: character, count: 4)
        let x12 = String(repeating: character, count: 12)
        self.init(uuidString: "\(x8)-\(x4)-\(x4)-\(x4)-\(x12)")!
    }
}
