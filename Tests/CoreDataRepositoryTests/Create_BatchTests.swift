// Create_BatchTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import XCTest

final class Create_BatchTests: CoreDataXCTestCase {
    func testCreate_Fetchable_Success() async throws {
        let modelType = FetchableModel_UuidId.self

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .create(_values, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)

        for value in successful {
            try await verify(value)
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreate_Fetchable_Failure() async throws {
        let modelType = FetchableModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            _ = try _values[0].asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .create(_values, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)

        for value in successful {
            try await verify(value)
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreate_Identifiable_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .create(_values, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)

        for value in successful {
            try await verify(value)
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreate_Identifiable_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            _ = try _values[0].asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .create(_values, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)

        for value in successful {
            try await verify(value)
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreate_ManagedIdUrlReferencable_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .create(_values, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)

        for value in successful {
            try await verify(value)
        }

        expectNoDifference(successful.map { $0.removingManagedIdUrl() }.sorted(), _values)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreate_ManagedIdUrlReferencable_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            _ = try _values[0].asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .create(_values, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)

        for value in successful {
            try await verify(value)
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreate_ManagedIdReferencable_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .create(_values, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)

        for value in successful {
            try await verify(value)
        }

        expectNoDifference(successful.map { $0.removingManagedId() }.sorted(), _values)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreate_ManagedIdReferencable_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            _ = try _values[0].asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let (successful, failed) = try await repository()
            .create(_values, transactionAuthor: transactionAuthor)

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)

        for value in successful {
            try await verify(value)
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreateAtomically_Fetchable_Success() async throws {
        let modelType = FetchableModel_UuidId.self

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let createdValues = try await repository()
            .createAtomically(_values, transactionAuthor: transactionAuthor).get()

        XCTAssertEqual(createdValues.count, _values.count)

        for value in createdValues {
            try await verify(value)
        }

        expectNoDifference(createdValues, _values)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreateAtomically_Fetchable_Failure() async throws {
        let modelType = FetchableModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let fetchRequest = modelType.managedFetchRequest()
        let existingValue = try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let value = try _values[0].asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return value
        }
        try await verify(modelType.init(managed: existingValue))

        let result = try await repository()
            .createAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectConstraintMerge)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }

        for value in _values[1 ... 4] {
            try await verifyDoesNotExist(value)
        }
    }

    func testCreateAtomically_Identifiable_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let createdValues = try await repository()
            .createAtomically(_values, transactionAuthor: transactionAuthor).get()

        XCTAssertEqual(createdValues.count, _values.count)

        for value in createdValues {
            try await verify(value)
        }

        expectNoDifference(createdValues, _values)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreateAtomically_Identifiable_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let fetchRequest = modelType.managedFetchRequest()
        let existingValue = try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let value = try _values[0].asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return value
        }
        try await verify(modelType.init(managed: existingValue))

        let result = try await repository()
            .createAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectConstraintMerge)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }

        for value in _values[1 ... 4] {
            try await verifyDoesNotExist(value)
        }
    }

    func testCreateAtomically_ManagedIdUrlReferencable_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let createdValues = try await repository()
            .createAtomically(_values, transactionAuthor: transactionAuthor).get()

        XCTAssertEqual(createdValues.count, _values.count)

        for value in createdValues {
            try await verify(value)
        }

        expectNoDifference(createdValues.map { $0.removingManagedIdUrl() }, _values)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreateAtomically_ManagedIdUrlReferencable_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let fetchRequest = modelType.managedFetchRequest()
        let existingValue = try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let value = try _values[0].asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return value
        }
        try await verify(modelType.init(managed: existingValue))

        let result = try await repository()
            .createAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectConstraintMerge)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }

        for value in _values[1 ... 4] {
            try await verifyDoesNotExist(value)
        }
    }

    func testCreateAtomically_ManagedIdReferencable_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let fetchRequest = modelType.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let createdValues = try await repository()
            .createAtomically(_values, transactionAuthor: transactionAuthor).get()

        XCTAssertEqual(createdValues.count, _values.count)

        for value in createdValues {
            try await verify(value)
        }

        expectNoDifference(createdValues.map { $0.removingManagedId() }, _values)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreateAtomically_ManagedIdReferencable_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let fetchRequest = modelType.managedFetchRequest()
        let existingValue = try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let value = try _values[0].asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return value
        }
        try await verify(modelType.init(managed: existingValue))

        let result = try await repository()
            .createAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectConstraintMerge)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }

        for value in _values[1 ... 4] {
            try await verifyDoesNotExist(value)
        }
    }
}
