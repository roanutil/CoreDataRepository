// UUID+Uniform.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import Foundation

extension UUID {
    @inlinable
    package init(uniform character: Character) {
        // swiftlint:disable identifier_name
        let x8 = String(repeating: character, count: 8)
        let x4 = String(repeating: character, count: 4)
        let x12 = String(repeating: character, count: 12)
        // swiftlint:enable identifier_name
        // BA7097EA-70FD-4595-9268-6D415A222C7B
        self.init(uuidString: "\(x8)-\(x4)-\(x4)-\(x4)-\(x12)")!
    }
}
