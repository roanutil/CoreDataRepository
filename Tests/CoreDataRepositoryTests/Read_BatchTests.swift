// Read_BatchTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import XCTest

final class Read_BatchTests: CoreDataXCTestCase {
    // MARK: Non Atomic

    func testRead_Identifiable_Success() async throws {
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

        let (successful, failed) = try await repository()
            .read(existingValues)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
    }

    func testRead_Identifiable_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]
        let (successful, failed) = try await repository()
            .read(_values)

        XCTAssertEqual(successful.count, 0)
        XCTAssertEqual(failed.count, _values.count)
    }

    func testRead_ManagedIdReferencable_Success() async throws {
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

        let (successful, failed) = try await repository()
            .read(existingValues)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
    }

    func testRead_ManagedIdReferencable_Failure() async throws {
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
            .read(_values)

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)
    }

    func testRead_ManagedIdReferencable_NoManagedId_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let (successful, failed) = try await repository()
            .read(_values)

        XCTAssertEqual(successful.count, 0)
        XCTAssertEqual(failed.count, _values.count)
    }

    func testRead_ManagedId_Success() async throws {
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

        let (successful, failed) = try await repository()
            .read(existingValues.compactMap(\.managedId), as: modelType)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
    }

    func testRead_ManagedId_Failure() async throws {
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
            .read(_values.map { try XCTUnwrap($0.managedId) }, as: modelType)

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)
    }

    func testRead_ManagedIdUrlReferencable_Success() async throws {
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

        let (successful, failed) = try await repository()
            .read(existingValues)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
    }

    func testRead_ManagedIdUrlReferencable_Failure() async throws {
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
            .read(_values)

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)
    }

    func testRead_ManagedIdUrlReferencable_NoManagedIdUrl_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let (successful, failed) = try await repository()
            .read(_values)

        XCTAssertEqual(successful.count, 0)
        XCTAssertEqual(failed.count, _values.count)
    }

    func testRead_ManagedIdUrl_Success() async throws {
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

        let (successful, failed) = try await repository()
            .read(existingValues.compactMap(\.managedIdUrl), as: modelType)

        XCTAssertEqual(successful.count, _values.count)
        XCTAssertEqual(failed.count, 0)
    }

    func testRead_ManagedIdUrl_Failure() async throws {
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
            .read(_values.map { try XCTUnwrap($0.managedIdUrl) }, as: modelType)

        XCTAssertEqual(successful.count, _values.count - 1)
        XCTAssertEqual(failed.count, 1)
    }

    // MARK: Atomic

    func testReadAtomically_Identifiable_Success() async throws {
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

        let values = try await repository()
            .readAtomically(existingValues).get()

        expectNoDifference(values, existingValues)
    }

    func testReadAtomically_Identifiable_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]
        let result = try await repository()
            .readAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noMatchFoundWhenReadingItem):
            break
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadAtomically_ManagedIdReferencable_Success() async throws {
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

        let values = try await repository()
            .readAtomically(existingValues).get()

        expectNoDifference(values, existingValues)
    }

    func testReadAtomically_ManagedIdReferencable_Failure() async throws {
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
            .readAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadAtomically_ManagedIdReferencable_NoManagedId_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let result = try await repository()
            .readAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noObjectIdOnItem):
            break
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadAtomically_ManagedId_Success() async throws {
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

        let values = try await repository()
            .readAtomically(existingValues.compactMap(\.managedId), as: modelType).get()

        expectNoDifference(values, existingValues)
    }

    func testReadAtomically_ManagedId_Failure() async throws {
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
            .readAtomically(_values.map { try XCTUnwrap($0.managedId) }, as: modelType)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadAtomically_ManagedIdUrlReferencable_Success() async throws {
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

        let values = try await repository()
            .readAtomically(existingValues).get()

        expectNoDifference(values, existingValues)
    }

    func testReadAtomically_ManagedIdUrlReferencable_Failure() async throws {
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
            .readAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadAtomically_ManagedIdUrlReferencable_NoManagedIdUrl_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _values = [
            modelType.seeded(1),
            modelType.seeded(2),
            modelType.seeded(3),
            modelType.seeded(4),
            modelType.seeded(5),
        ]

        let result = try await repository()
            .readAtomically(_values)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noUrlOnItemToMapToObjectId):
            break
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadAtomically_ManagedIdUrl_Success() async throws {
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

        let values = try await repository()
            .readAtomically(existingValues.compactMap(\.managedIdUrl), as: modelType).get()

        expectNoDifference(values, existingValues)
    }

    func testReadAtomically_ManagedIdUrl_Failure() async throws {
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
            .readAtomically(_values.map { try XCTUnwrap($0.managedIdUrl) }, as: modelType)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }
}
