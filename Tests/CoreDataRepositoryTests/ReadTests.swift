// ReadTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import Testing

extension CoreDataRepositoryTests {
    @Suite
    struct ReadTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        @Test(arguments: [false, true])
        func read_Identifiable_Success(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue, _value)

            try await verify(existingValue)

            let value = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .read(existingValue).get()
                }
            } else {
                try await repository
                    .read(existingValue).get()
            }

            expectNoDifference(value, existingValue)
        }

        @Test(arguments: [false, true])
        func read_Identifiable_Failure(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(_value)
                }
            } else {
                await repository
                    .read(_value)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noMatchFoundWhenReadingItem):
                return
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test(arguments: [false, true])
        func read_Identifiable_ById_Success(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue, _value)

            try await verify(existingValue)

            let value = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .read(existingValue.id, of: modelType).get()
                }
            } else {
                try await repository
                    .read(existingValue.id, of: modelType).get()
            }

            expectNoDifference(value, existingValue)
        }

        @Test(arguments: [false, true])
        func read_Identifiable_ById_Failure(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(_value.id, of: modelType)
                }
            } else {
                await repository
                    .read(_value.id, of: modelType)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noMatchFoundWhenReadingItem):
                return
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test(arguments: [false, true])
        func readSubscription_Identifiable_Success(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue, _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    repository
                        .readSubscription(_value)
                }
            } else {
                repository
                    .readSubscription(_value)
            }
            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()?.get()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()?.get()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func readThrowingSubscription_Identifiable_Success(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue, _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    repository
                        .readThrowingSubscription(_value)
                }
            } else {
                repository
                    .readThrowingSubscription(_value)
            }
            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func readSubscription_Identifiable_ById_Success(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue, _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    repository
                        .readSubscription(_value.id, of: modelType)
                }
            } else {
                repository
                    .readSubscription(_value.id, of: modelType)
            }
            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()?.get()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()?.get()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func readThrowingSubscription_Identifiable_ById_Success(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue, _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    repository
                        .readThrowingSubscription(_value.id, of: modelType)
                }
            } else {
                repository
                    .readThrowingSubscription(_value.id, of: modelType)
            }
            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func read_ManagedId_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue.removingManagedId(), _value)

            try await verify(existingValue)

            let value = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .read(#require(existingValue.managedId), of: modelType).get()
                }
            } else {
                try await repository
                    .read(#require(existingValue.managedId), of: modelType).get()
            }

            expectNoDifference(value, existingValue)
        }

        @Test(arguments: [false, true])
        func read_ManagedId_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                try repositoryContext.obtainPermanentIDs(for: [managed])

                let value = try modelType.init(managed: managed)

                repositoryContext.delete(managed)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return value
            }

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .read(#require(existingValue.managedId), of: modelType)
                }
            } else {
                try await repository
                    .read(#require(existingValue.managedId), of: modelType)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test(arguments: [false, true])
        func readSubscription_ManagedId_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue.removingManagedId(), _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    try repository
                        .readSubscription(#require(existingValue.managedId), of: modelType)
                }
            } else {
                try repository
                    .readSubscription(#require(existingValue.managedId), of: modelType)
            }
            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()?.get()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()?.get()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func readThrowingSubscription_ManagedId_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue.removingManagedId(), _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    try repository
                        .readThrowingSubscription(#require(existingValue.managedId), of: modelType)
                }
            } else {
                try repository
                    .readThrowingSubscription(#require(existingValue.managedId), of: modelType)
            }
            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue.removingManagedId(), _value)

            try await verify(existingValue)

            let value = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .read(existingValue).get()
                }
            } else {
                try await repository
                    .read(existingValue).get()
            }

            expectNoDifference(value, existingValue)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdReferencable_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                try repositoryContext.obtainPermanentIDs(for: [managed])

                let value = try modelType.init(managed: managed)

                repositoryContext.delete(managed)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return value
            }

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(existingValue)
                }
            } else {
                await repository
                    .read(existingValue)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test(arguments: [false, true])
        func read_ManagedIdReferencable_NoManagedId_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(_value)
                }
            } else {
                await repository
                    .read(_value)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noObjectIdOnItem):
                return
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test(arguments: [false, true])
        func readSubscription_ManagedIdReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue.removingManagedId(), _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    repository
                        .readSubscription(existingValue)
                }
            } else {
                repository
                    .readSubscription(existingValue)
            }
            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()?.get()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()?.get()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func readThrowingSubscription_ManagedIdReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue.removingManagedId(), _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    repository
                        .readThrowingSubscription(existingValue)
                }
            } else {
                repository
                    .readThrowingSubscription(existingValue)
            }

            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdUrl_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            try await verify(existingValue)

            let value = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .read(#require(existingValue.managedIdUrl), of: modelType).get()
                }
            } else {
                try await repository
                    .read(#require(existingValue.managedIdUrl), of: modelType).get()
            }

            expectNoDifference(value, existingValue)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdUrl_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                try repositoryContext.obtainPermanentIDs(for: [managed])

                let value = try modelType.init(managed: managed)

                repositoryContext.delete(managed)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return value
            }

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .read(#require(existingValue.managedIdUrl), of: modelType)
                }
            } else {
                try await repository
                    .read(#require(existingValue.managedIdUrl), of: modelType)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test(arguments: [false, true])
        func readSubscription_ManagedIdUrl_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    try repository
                        .readSubscription(#require(existingValue.managedIdUrl), of: modelType)
                }
            } else {
                try repository
                    .readSubscription(#require(existingValue.managedIdUrl), of: modelType)
            }

            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()?.get()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()?.get()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func readThrowingSubscription_ManagedIdUrl_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    repository
                        .readThrowingSubscription(existingValue)
                }
            } else {
                repository
                    .readThrowingSubscription(existingValue)
            }

            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdUrlReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            try await verify(existingValue)

            let value = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .read(existingValue).get()
                }
            } else {
                try await repository
                    .read(existingValue).get()
            }

            expectNoDifference(value, existingValue)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdUrlReferencable_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                try repositoryContext.obtainPermanentIDs(for: [managed])

                let value = try modelType.init(managed: managed)

                repositoryContext.delete(managed)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return value
            }

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(existingValue)
                }
            } else {
                await repository
                    .read(existingValue)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test(arguments: [false, true])
        func read_ManagedIdUrlReferencable_NoManagedId_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(_value)
                }
            } else {
                await repository
                    .read(_value)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noUrlOnItemToMapToObjectId):
                return
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test(arguments: [false, true])
        func readSubscription_ManagedIdUrlReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    repository
                        .readSubscription(existingValue)
                }
            } else {
                repository
                    .readSubscription(existingValue)
            }

            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()?.get()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()?.get()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        @Test(arguments: [false, true])
        func readThrowingSubscription_ManagedIdUrlReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            var (existingValue, managed) = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try (modelType.init(managed: managed), managed)
            }
            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            try await verify(existingValue)

            let stream = if inTransaction {
                try await repository.withTransaction { _ in
                    repository
                        .readThrowingSubscription(existingValue)
                }
            } else {
                repository
                    .readThrowingSubscription(existingValue)
            }

            var iterator = stream.makeAsyncIterator()
            var _latestValue = try await iterator.next()
            var latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)

            existingValue = try await repositoryContext.perform(schedule: .immediate) {
                managed.int += 1
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            _latestValue = try await iterator.next()
            latestValue = try #require(_latestValue)

            expectNoDifference(latestValue, existingValue)
        }

        init(
            container: NSPersistentContainer,
            repositoryContext: NSManagedObjectContext,
            repository: CoreDataRepository
        ) {
            self.container = container
            self.repositoryContext = repositoryContext
            self.repository = repository
        }
    }
}
