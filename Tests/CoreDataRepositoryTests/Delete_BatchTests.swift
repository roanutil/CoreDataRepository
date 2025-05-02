// Delete_BatchTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import XCTest

final class Delete_BatchTests: CoreDataXCTestCase {
    // MARK: Non Atomic

    func testDelete_Identifiable_Success() async throws {
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

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .delete(existingValues, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDelete_Identifiable_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]
        let (successful, failed) = try await repository()
            .delete(_values)

        XCTAssertEqual(successful.count, 0)
        XCTAssertEqual(failed.count, _values.count)
    }

    func testDelete_ManagedIdReferencable_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
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
        expectNoDifference(existingValues.map { $0.removingManagedId() }, _values)

        for value in existingValues {
            try await verify(value)
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .delete(existingValues, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
        for value in existingValues {
            try await verifyDoesNotExist(value)
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDelete_ManagedIdReferencable_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _values = try await repositoryContext().perform(schedule: .immediate) {
            let manageds = try [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ].map { try $0.asManagedModel(in: self.repositoryContext()) }
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: manageds)
            let values = try manageds.map { try modelType.init(managed: $0) }

            try self.repositoryContext().delete(manageds[0])
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return values
        }

        let (successful, failed) = try await repository()
            .delete(_values)

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)
        for value in _values[1 ... 4] {
            try await verifyDoesNotExist(value)
        }
    }

    func testDelete_ManagedIdReferencable_NoManagedId_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let (successful, failed) = try await repository()
            .delete(_values)

        XCTAssertEqual(successful.count, 0)
        XCTAssertEqual(failed.count, _values.count)
    }

    func testDelete_ManagedId_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
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
        expectNoDifference(existingValues.map { $0.removingManagedId() }, _values)

        for value in existingValues {
            try await verify(value)
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .delete(existingValues.compactMap(\.managedId), transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
        for value in existingValues {
            try await verifyDoesNotExist(value)
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDelete_ManagedId_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _values = try await repositoryContext().perform(schedule: .immediate) {
            let manageds = try [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ].map { try $0.asManagedModel(in: self.repositoryContext()) }
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: manageds)
            let values = try manageds.map { try modelType.init(managed: $0) }

            try self.repositoryContext().delete(manageds[0])
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return values
        }

        for value in _values[1 ... 4] {
            try await verify(value)
        }
        try await verifyDoesNotExist(_values[0])

        let (successful, failed) = try await repository()
            .delete(_values.map { try XCTUnwrap($0.managedId) })

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)
        for value in _values[1 ... 4] {
            try await verifyDoesNotExist(value)
        }
    }

    func testDelete_ManagedIdUrlReferencable_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
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
        expectNoDifference(existingValues.map { $0.removingManagedIdUrl() }, _values)

        for value in existingValues {
            try await verify(value)
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .delete(existingValues, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
        for value in existingValues {
            try await verifyDoesNotExist(value)
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDelete_ManagedIdUrlReferencable_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _values = try await repositoryContext().perform(schedule: .immediate) {
            let manageds = try [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ].map { try $0.asManagedModel(in: self.repositoryContext()) }
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: manageds)
            let values = try manageds.map { try modelType.init(managed: $0) }

            try self.repositoryContext().delete(manageds[0])
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return values
        }

        let (successful, failed) = try await repository()
            .delete(_values)

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)
        for value in _values {
            try await verifyDoesNotExist(value)
        }
    }

    func testDelete_ManagedIdUrlReferencable_NoManagedIdUrl_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let (successful, failed) = try await repository()
            .delete(_values)

        XCTAssertEqual(successful.count, 0)
        XCTAssertEqual(failed.count, _values.count)
    }

    func testDelete_ManagedIdUrl_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
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
        expectNoDifference(existingValues.map { $0.removingManagedIdUrl() }, _values)

        for value in existingValues {
            try await verify(value)
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .delete(existingValues.compactMap(\.managedIdUrl), transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
        for value in existingValues {
            try await verifyDoesNotExist(value)
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDelete_ManagedIdUrl_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _values = try await repositoryContext().perform(schedule: .immediate) {
            let manageds = try [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ].map { try $0.asManagedModel(in: self.repositoryContext()) }
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: manageds)
            let values = try manageds.map { try modelType.init(managed: $0) }

            try self.repositoryContext().delete(manageds[0])
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return values
        }

        let (successful, failed) = try await repository()
            .delete(_values.map { try XCTUnwrap($0.managedIdUrl) })

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)
        for value in _values[1 ... 4] {
            try await verifyDoesNotExist(value)
        }
    }

    // MARK: Atomic

    func testDeleteAtomically_Identifiable_Success() async throws {
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

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        try await repository()
            .deleteAtomically(existingValues, transactionAuthor: transactionAuthor).get()

        for value in existingValues {
            try await verifyDoesNotExist(value)
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDeleteAtomically_Identifiable_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]
        let result = try await repository()
            .deleteAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noMatchFoundWhenReadingItem):
            break
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDeleteAtomically_ManagedIdReferencable_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
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
        expectNoDifference(existingValues.map { $0.removingManagedId() }, _values)

        for value in existingValues {
            try await verify(value)
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        try await repository()
            .deleteAtomically(existingValues, transactionAuthor: transactionAuthor).get()

        for value in existingValues {
            try await verifyDoesNotExist(value)
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDeleteAtomically_ManagedIdReferencable_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _values = try await repositoryContext().perform(schedule: .immediate) {
            let manageds = try [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ].map { try $0.asManagedModel(in: self.repositoryContext()) }
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: manageds)
            let values = try manageds.map { try modelType.init(managed: $0) }

            try self.repositoryContext().delete(manageds[0])
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return values
        }

        let result = try await repository()
            .deleteAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }

        for value in _values[1 ... 4] {
            try await verify(value)
        }
        try await verifyDoesNotExist(_values[0])
    }

    func testDeleteAtomically_ManagedIdReferencable_NoManagedId_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let result = try await repository()
            .deleteAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noObjectIdOnItem):
            break
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDeleteAtomically_ManagedId_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
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
        expectNoDifference(existingValues.map { $0.removingManagedId() }, _values)

        for value in existingValues {
            try await verify(value)
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        try await repository()
            .deleteAtomically(existingValues.compactMap(\.managedId), transactionAuthor: transactionAuthor).get()

        for value in existingValues {
            try await verifyDoesNotExist(value)
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDeleteAtomically_ManagedId_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _values = try await repositoryContext().perform(schedule: .immediate) {
            let manageds = try [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ].map { try $0.asManagedModel(in: self.repositoryContext()) }
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: manageds)
            let values = try manageds.map { try modelType.init(managed: $0) }

            try self.repositoryContext().delete(manageds[0])
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return values
        }

        for value in _values[1 ... 4] {
            try await verify(value)
        }
        try await verifyDoesNotExist(_values[0])

        let result = try await repository()
            .deleteAtomically(_values.map { try XCTUnwrap($0.managedId) })

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }

        for value in _values[1 ... 4] {
            try await verify(value)
        }
        try await verifyDoesNotExist(_values[0])
    }

    func testDeleteAtomically_ManagedIdUrlReferencable_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
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
        expectNoDifference(existingValues.map { $0.removingManagedIdUrl() }, _values)

        for value in existingValues {
            try await verify(value)
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        try await repository()
            .deleteAtomically(existingValues, transactionAuthor: transactionAuthor).get()

        for value in existingValues {
            try await verifyDoesNotExist(value)
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDeleteAtomically_ManagedIdUrlReferencable_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _values = try await repositoryContext().perform(schedule: .immediate) {
            let manageds = try [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ].map { try $0.asManagedModel(in: self.repositoryContext()) }
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: manageds)
            let values = try manageds.map { try modelType.init(managed: $0) }

            try self.repositoryContext().delete(manageds[0])
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return values
        }

        let result = try await repository()
            .deleteAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }

        for value in _values[1 ... 4] {
            try await verify(value)
        }
        try await verifyDoesNotExist(_values[0])
    }

    func testDeleteAtomically_ManagedIdUrlReferencable_NoManagedIdUrl_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let result = try await repository()
            .deleteAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noUrlOnItemToMapToObjectId):
            break
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDeleteAtomically_ManagedIdUrl_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
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
        expectNoDifference(existingValues.map { $0.removingManagedIdUrl() }, _values)

        for value in existingValues {
            try await verify(value)
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        try await repository()
            .deleteAtomically(existingValues.compactMap(\.managedIdUrl), transactionAuthor: transactionAuthor).get()

        for value in existingValues {
            try await verifyDoesNotExist(value)
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDeleteAtomically_ManagedIdUrl_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _values = try await repositoryContext().perform(schedule: .immediate) {
            let manageds = try [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ].map { try $0.asManagedModel(in: self.repositoryContext()) }
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: manageds)
            let values = try manageds.map { try modelType.init(managed: $0) }

            try self.repositoryContext().delete(manageds[0])
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return values
        }

        let result = try await repository()
            .deleteAtomically(_values.map { try XCTUnwrap($0.managedIdUrl) })

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }

        for value in _values[1 ... 4] {
            try await verify(value)
        }
        try await verifyDoesNotExist(_values[0])
    }
}
