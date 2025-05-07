// ReadTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import XCTest

final class ReadTests: CoreDataXCTestCase {
    func testRead_Identifiable_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _value = modelType.seeded(1)
        let existingValue = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }
        expectNoDifference(existingValue, _value)

        try await verify(existingValue)

        let value = try await repository()
            .read(existingValue).get()

        expectNoDifference(value, existingValue)
    }

    func testRead_Identifiable_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _value = modelType.seeded(1)
        let result = try await repository()
            .read(_value)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noMatchFoundWhenReadingItem):
            return
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRead_Identifiable_ById_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self
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
            .read(existingValue.id, of: modelType).get()
    }

    func testRead_Identifiable_ById_Failure() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _value = modelType.seeded(1)
        let result = try await repository()
            .read(_value.id, of: modelType)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noMatchFoundWhenReadingItem):
            return
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadSubscription_Identifiable_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue, _value)

        try await verify(existingValue)

        let stream = try repository()
            .readSubscription(_value)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()?.get()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()?.get()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testReadThrowingSubscription_Identifiable_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue, _value)

        try await verify(existingValue)

        let stream = try repository()
            .readThrowingSubscription(_value)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testReadSubscription_Identifiable_ById_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue, _value)

        try await verify(existingValue)

        let stream = try repository()
            .readSubscription(_value.id, of: modelType)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()?.get()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()?.get()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testReadThrowingSubscription_Identifiable_ById_Success() async throws {
        let modelType = IdentifiableModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue, _value)

        try await verify(existingValue)

        let stream = try repository()
            .readThrowingSubscription(_value.id, of: modelType)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testRead_ManagedId_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
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
            .read(XCTUnwrap(existingValue.managedId), of: modelType).get()
    }

    func testRead_ManagedId_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self
        let _value = modelType.seeded(1)
        let existingValue = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
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
            .read(XCTUnwrap(existingValue.managedId), of: modelType)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadSubscription_ManagedId_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue.removingManagedId(), _value)

        try await verify(existingValue)

        let stream = try repository()
            .readSubscription(XCTUnwrap(existingValue.managedId), of: modelType)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()?.get()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()?.get()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testReadThrowingSubscription_ManagedId_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue.removingManagedId(), _value)

        try await verify(existingValue)

        let stream = try repository()
            .readThrowingSubscription(XCTUnwrap(existingValue.managedId), of: modelType)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testRead_ManagedIdReferencable_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
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
            .read(existingValue).get()
    }

    func testRead_ManagedIdReferencable_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self
        let _value = modelType.seeded(1)
        let existingValue = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
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
            .read(existingValue)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRead_ManagedIdReferencable_NoManagedId_Failure() async throws {
        let modelType = ManagedIdModel_UuidId.self
        let _value = modelType.seeded(1)
        let result = try await repository()
            .read(_value)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noObjectIdOnItem):
            return
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadSubscription_ManagedIdReferencable_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue.removingManagedId(), _value)

        try await verify(existingValue)

        let stream = try repository()
            .readSubscription(existingValue)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()?.get()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()?.get()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testReadThrowingSubscription_ManagedIdReferencable_Success() async throws {
        let modelType = ManagedIdModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue.removingManagedId(), _value)

        try await verify(existingValue)

        let stream = try repository()
            .readThrowingSubscription(existingValue)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testRead_ManagedIdUrl_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
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
            .read(XCTUnwrap(existingValue.managedIdUrl), of: modelType).get()
    }

    func testRead_ManagedIdUrl_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
        let _value = modelType.seeded(1)
        let existingValue = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
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
            .read(XCTUnwrap(existingValue.managedIdUrl), of: modelType)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadSubscription_ManagedIdUrl_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue.removingManagedIdUrl(), _value)

        try await verify(existingValue)

        let stream = try repository()
            .readSubscription(XCTUnwrap(existingValue.managedIdUrl), of: modelType)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()?.get()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()?.get()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testReadThrowingSubscription_ManagedIdUrl_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue.removingManagedIdUrl(), _value)

        try await verify(existingValue)

        let stream = try repository()
            .readThrowingSubscription(existingValue)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testRead_ManagedIdUrlReferencable_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
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
            .read(existingValue).get()
    }

    func testRead_ManagedIdUrlReferencable_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
        let _value = modelType.seeded(1)
        let existingValue = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
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
            .read(existingValue)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case let .failure(.cocoa(cocoaError)):
            XCTAssertEqual(cocoaError.code, .managedObjectReferentialIntegrity)
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRead_ManagedIdUrlReferencable_NoManagedId_Failure() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
        let _value = modelType.seeded(1)
        let result = try await repository()
            .read(_value)

        switch result {
        case .success:
            XCTFail("Not expecting success")
        case .failure(.noUrlOnItemToMapToObjectId):
            return
        case let .failure(error):
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadSubscription_ManagedIdUrlReferencable_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue.removingManagedIdUrl(), _value)

        try await verify(existingValue)

        let stream = try repository()
            .readSubscription(existingValue)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()?.get()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()?.get()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }

    func testReadThrowingSubscription_ManagedIdUrlReferencable_Success() async throws {
        let modelType = ManagedIdUrlModel_UuidId.self
        let _value = modelType.seeded(1)
        var (existingValue, managed) = try await repositoryContext().perform(schedule: .immediate) {
            let managed = try _value.asManagedModel(in: self.repositoryContext())
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try (modelType.init(managed: managed), managed)
        }
        expectNoDifference(existingValue.removingManagedIdUrl(), _value)

        try await verify(existingValue)

        let stream = try repository()
            .readThrowingSubscription(existingValue)
        var iterator = stream.makeAsyncIterator()
        var _latestValue = try await iterator.next()
        var latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)

        existingValue = try await repositoryContext().perform(schedule: .immediate) {
            managed.int += 1
            try self.repositoryContext().save()
            try self.repositoryContext().parent?.save()
            return try modelType.init(managed: managed)
        }

        _latestValue = try await iterator.next()
        latestValue = try XCTUnwrap(_latestValue)

        expectNoDifference(latestValue, existingValue)
    }
}
