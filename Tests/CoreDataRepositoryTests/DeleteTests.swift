// DeleteTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import XCTest

final class DeleteTests: CoreDataXCTestCase {
    func testDelete_Identifiable_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let transactionAuthor: String = #function
        let _value = modelType.seeded(1)
        let existingValue = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }
        expectNoDifference(existingValue, _value)

        try await verify(existingValue)

        _ = try await repository()
            .delete(_value, transactionAuthor: transactionAuthor).get()
    }

    func testDelete_Identifiable_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _value = modelType.seeded(1)
        let result = try await repository()
            .delete(_value)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noMatchFoundWhenReadingItem):
            return
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDelete_ManagedIdReferencable_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
        let transactionAuthor: String = #function
        let _value = modelType.seeded(1)
        let existingValue = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }
        expectNoDifference(existingValue.removingManagedId(), _value)

        try await verify(existingValue)

        _ = try await repository()
            .delete(existingValue, transactionAuthor: transactionAuthor)
    }

    func testDelete_ManagedIdReferencable_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _value = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try modelType.seeded(1).asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: [managed])
            let value = try modelType.init(managed: managed)

            try self.repositoryContext().delete(managed)
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return value
        }

        let result = try await repository()
            .delete(_value)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDelete_ManagedIdReferencable_NoManagedId_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _value = modelType.seeded(1)

        let result = try await repository()
            .delete(_value)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noObjectIdOnItem):
            return
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDelete_ManagedId_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
        let transactionAuthor: String = #function
        let _value = modelType.seeded(1)
        let existingValue = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }
        expectNoDifference(existingValue.removingManagedId(), _value)

        try await verify(existingValue)

        _ = try await repository()
            .delete(XCTUnwrap(existingValue.managedId), transactionAuthor: transactionAuthor)
    }

    func testDelete_ManagedId_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self

        let _value = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try modelType.seeded(1).asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: [managed])
            let value = try modelType.init(managed: managed)

            try self.repositoryContext().delete(managed)
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return value
        }

        let result = try await repository()
            .delete(XCTUnwrap(_value.managedId))

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDelete_ManagedIdUrlReferencable_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
        let transactionAuthor: String = #function
        let _value = modelType.seeded(1)
        let existingValue = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }
        expectNoDifference(existingValue.removingManagedIdUrl(), _value)

        try await verify(existingValue)

        _ = try await repository()
            .delete(existingValue, transactionAuthor: transactionAuthor)
    }

    func testDelete_ManagedIdUrlReferencable_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _value = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try modelType.seeded(1).asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: [managed])
            let value = try modelType.init(managed: managed)

            try self.repositoryContext().delete(managed)
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return value
        }

        let result = try await repository()
            .delete(_value)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDelete_ManagedIdUrlReferencable_NoManagedIdUrl_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _value = modelType.seeded(1)

        let result = try await repository()
            .delete(_value)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noUrlOnItemToMapToObjectId):
            return
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDelete_ManagedIdUrl_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
        let transactionAuthor: String = #function
        let _value = modelType.seeded(1)
        let existingValue = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }
        expectNoDifference(existingValue.removingManagedIdUrl(), _value)

        try await verify(existingValue)

        _ = try await repository()
            .delete(XCTUnwrap(existingValue.managedIdUrl), transactionAuthor: transactionAuthor)
    }

    func testDelete_ManagedIdUrl_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self

        let _value = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try modelType.seeded(1).asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            try self.repositoryContext().obtainPermanentIDs(for: [managed])
            let value = try modelType.init(managed: managed)

            try self.repositoryContext().delete(managed)
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()

            return value
        }

        let result = try await repository()
            .delete(XCTUnwrap(_value.managedIdUrl))

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
