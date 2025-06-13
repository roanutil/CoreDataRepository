// UpdateTests.swift
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
    struct UpdateTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        @Test
        func update_Identifiable_Success() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)
            var existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            expectNoDifference(existingValue, _value)

            try await verify(existingValue)

            existingValue.bool.toggle()

            let updatedValue = try await repository
                .update(with: existingValue, transactionAuthor: transactionAuthor).get()

            expectNoDifference(updatedValue, existingValue)

            try await verify(existingValue)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func update_Identifiable_Failure() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)
            let result = await repository
                .update(with: _value)

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
        func update_ManagedIdReferencable_Success() async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            var existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue.removingManagedId(), _value)

            try await verify(existingValue)

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            existingValue.bool.toggle()

            let updatedValue = try await repository
                .update(with: existingValue, transactionAuthor: transactionAuthor).get()

            expectNoDifference(updatedValue, existingValue)

            try await verify(existingValue)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func update_ManagedIdReferencable_Failure() async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            let result = await repository
                .update(with: _value)

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
        func update_ManagedId_Success() async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            var existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            expectNoDifference(existingValue.removingManagedId(), _value)

            try await verify(existingValue)

            existingValue.bool.toggle()

            let updatedValue = try await repository
                .update(#require(existingValue.managedId), with: existingValue, transactionAuthor: transactionAuthor)
                .get()

            expectNoDifference(updatedValue, existingValue)

            try await verify(existingValue)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func update_ManagedId_Failure() async throws {
            let modelType = ManagedIdModel_UuidId.self
            let _value = modelType.seeded(1)
            var existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                let value = try modelType.init(managed: managed)

                repositoryContext.delete(managed)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return value
            }

            expectNoDifference(existingValue.removingManagedId(), _value)

            existingValue.bool.toggle()

            let result = try await repository
                .update(#require(existingValue.managedId), with: existingValue)

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
        func update_ManagedIdUrlReferencable_Success() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            var existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            try await verify(existingValue)

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            existingValue.bool.toggle()

            let updatedValue = try await repository
                .update(with: existingValue, transactionAuthor: transactionAuthor).get()

            expectNoDifference(updatedValue, existingValue)

            try await verify(existingValue)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func update_ManagedIdUrlReferencable_Failure() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            let result = await repository
                .update(with: _value)

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
        func update_ManagedIdUrl_Success() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            var existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            try await verify(existingValue)

            existingValue.bool.toggle()

            let updatedValue = try await repository
                .update(
                    #require(existingValue.managedIdUrl),
                    with: existingValue,
                    transactionAuthor: transactionAuthor
                )
                .get()

            expectNoDifference(updatedValue, existingValue)

            try await verify(existingValue)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func update_ManagedIdUrl_Failure() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let _value = modelType.seeded(1)
            var existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                let value = try modelType.init(managed: managed)

                repositoryContext.delete(managed)
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return value
            }

            expectNoDifference(existingValue.removingManagedIdUrl(), _value)

            existingValue.bool.toggle()

            let result = try await repository
                .update(#require(existingValue.managedIdUrl), with: existingValue)

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
