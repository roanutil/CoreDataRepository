// DeleteTests.swift
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
    struct DeleteTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        @Test
        func delete_Identifiable_Success() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue, _value)

            try await verify(existingValue)

            _ = try await repository
                .delete(_value, transactionAuthor: transactionAuthor).get()
        }

        @Test
        func delete_Identifiable_Failure() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)
            let result = await repository
                .delete(_value)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noMatchFoundWhenReadingItem):
                return
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func delete_ManagedIdReferencable_Success() async throws {
            let modelType = ManagedIdModel_UuidId.self
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue.removingManagedId(), _value)

            try await verify(existingValue)

            _ = await repository
                .delete(existingValue, transactionAuthor: transactionAuthor)
        }

        @Test
        func delete_ManagedIdReferencable_Failure() async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _value = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try modelType.seeded(1).asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: [managed])
                let value = try modelType.init(managed: managed)

                repositoryContext.delete(managed)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return value
            }

            let result = await repository
                .delete(_value)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func delete_ManagedIdReferencable_NoManagedId_Failure() async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _value = modelType.seeded(1)

            let result = await repository
                .delete(_value)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noObjectIdOnItem):
                return
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func delete_ManagedId_Success() async throws {
            let modelType = ManagedIdModel_UuidId.self
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue.removingManagedId(), _value)

            try await verify(existingValue)

            _ = try await repository
                .delete(#require(existingValue.managedId), transactionAuthor: transactionAuthor)
        }

        @Test
        func delete_ManagedId_Failure() async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _value = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try modelType.seeded(1).asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: [managed])
                let value = try modelType.init(managed: managed)

                repositoryContext.delete(managed)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return value
            }

            let result = try await repository
                .delete(#require(_value.managedId))

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func delete_ManagedIdUrlReferencable_Success() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            try await verify(existingValue)

            _ = await repository
                .delete(existingValue, transactionAuthor: transactionAuthor)
        }

        @Test
        func delete_ManagedIdUrlReferencable_Failure() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _value = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try modelType.seeded(1).asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: [managed])
                let value = try modelType.init(managed: managed)

                repositoryContext.delete(managed)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return value
            }

            let result = await repository
                .delete(_value)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func delete_ManagedIdUrlReferencable_NoManagedIdUrl_Failure() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _value = modelType.seeded(1)

            let result = await repository
                .delete(_value)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noUrlOnItemToMapToObjectId):
                return
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func delete_ManagedIdUrl_Success() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            try await verify(existingValue)

            _ = try await repository
                .delete(#require(existingValue.managedIdUrl), transactionAuthor: transactionAuthor)
        }

        @Test
        func delete_ManagedIdUrl_Failure() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _value = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try modelType.seeded(1).asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: [managed])
                let value = try modelType.init(managed: managed)

                repositoryContext.delete(managed)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return value
            }

            let result = try await repository
                .delete(#require(_value.managedIdUrl))

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
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
