// Update_BatchTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import XCTest

final class Update_BatchTests: CoreDataXCTestCase {
    // MARK: Non Atomic

    func testUpdate_Identifiable_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]
        var existingValues = try await repositoryContext().perform(schedule: .immediate) {
            let manageds = try _values.map { try $0.asManagedModel(in: self.repositoryContext()) }
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try manageds.map { try modelType.init(managed: $0) }
        }
        expectNoDifference(existingValues, _values)

        for value in existingValues {
            try await verify(value)
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        existingValues = existingValues.map { value in
            var value = value
            value.int += 1
            return value
        }

        let (successful, failed) = try await repository()
            .update(existingValues, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
        for value in successful {
            try await verify(value)
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testUpdate_Identifiable_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]
        let (successful, failed) = try await repository()
            .update(_values)

        XCTAssertEqual(successful.count, 0)
        XCTAssertEqual(failed.count, _values.count)
    }

    // MARK: Atomic

    func testUpdateAtomically_Identifiable_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]
        let existingValues = try await repositoryContext().perform(schedule: .immediate) {
            let manageds = try _values.map { try $0.asManagedModel(in: self.repositoryContext()) }
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try manageds.map { try modelType.init(managed: $0) }
        }
        expectNoDifference(existingValues, _values)

        for value in existingValues {
            try await verify(value)
        }

        let updatedValues = try await repository()
            .updateAtomically(existingValues).get()

        for value in updatedValues {
            try await verify(value)
        }
    }

    func testUpdateAtomically_Identifiable_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]
        let result = try await repository()
            .updateAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noMatchFoundWhenReadingItem):
            break
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }
}
