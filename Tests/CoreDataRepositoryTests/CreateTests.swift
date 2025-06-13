// CreateTests.swift
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
    struct CreateTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        @Test
        func create_Fetchable_Success() async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let value = try await repository
                .create(_value, transactionAuthor: transactionAuthor).get()
            expectNoDifference(value, _value)

            try await verify(value)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_Fetchable_Failure() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)
            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }
            expectNoDifference(existingValue, _value)

            try await verify(existingValue)

            let result = await repository
                .create(_value)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectConstraintMerge)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func create_Identifiable_Success() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let value = try await repository
                .create(_value, transactionAuthor: transactionAuthor).get()
            expectNoDifference(value, _value)

            try await verify(value)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_Identifiable_Failure() async throws {
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

            let result = await repository
                .create(_value)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectConstraintMerge)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func create_ManagedIdReferencable_Success() async throws {
            let modelType = ManagedIdModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let value = try await repository
                .create(_value, transactionAuthor: transactionAuthor).get()
            expectNoDifference(value.removingManagedId(), _value)

            try await verify(value)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_ManagedIdReferencable_Failure() async throws {
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

            let result = await repository
                .create(_value)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectConstraintMerge)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func create_ManagedIdUrlReferencable_Success() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let value = try await repository
                .create(_value, transactionAuthor: transactionAuthor).get()
            expectNoDifference(value.removingManagedIdUrl(), _value)

            try await verify(value)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_ManagedIdUrlReferencable_Failure() async throws {
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

            let result = await repository
                .create(_value)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectConstraintMerge)
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
