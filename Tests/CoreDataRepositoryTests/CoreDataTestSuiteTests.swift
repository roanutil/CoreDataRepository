// CoreDataTestSuiteTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

// CoreDataTestSuiteTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import Internal
import Testing

extension CoreDataRepositoryTests {
    @Suite
    struct CoreDataTestSuiteTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        @Test
        func verify_Fetchable_Success() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            try await verify(existingValue)
        }

        @Test
        func verify_Fetchable_Failure() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            await withKnownIssue {
                try await verify(_value)
            }
        }

        @Test
        func verify_Readable_Success() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)

            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            try await verify(existingValue)
        }

        @Test
        func verify_Readable_Failure() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)

            await withKnownIssue {
                try await verify(_value)
            }
        }

        @Test
        func verifyDoesNotExist_Fetchable_Success() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            try await verifyDoesNotExist(_value)
        }

        @Test
        func verifyDoesNotExist_Fetchable_Failure() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            await withKnownIssue {
                try await verifyDoesNotExist(existingValue)
            }
        }

        @Test
        func verifyDoesNotExist_Readable_Success() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)

            try await verifyDoesNotExist(_value)
        }

        @Test
        func verifyDoesNotExist_Readable_Failure() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _value = modelType.seeded(1)

            let existingValue = try await repositoryContext.perform(schedule: .immediate) {
                let managed = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try modelType.init(managed: managed)
            }

            await withKnownIssue {
                try await verifyDoesNotExist(existingValue)
            }
        }

        @Test
        func verifyHistory_Success() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            let author: String = #function
            let date = Date.now

            try await repositoryContext.perform(schedule: .immediate) {
                repositoryContext.transactionAuthor = author
                _ = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            try verify(transactionAuthor: author, timeStamp: date)
        }

        @Test
        func verifyHistory_Failure_NoHistory() async throws {
            let author: String = #function
            let date = Date.now

            withKnownIssue {
                try verify(transactionAuthor: author, timeStamp: date)
            }
        }

        @Test
        func verifyHistory_Failure_WrongAuthor() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            let author: String = #function
            let date = Date.now

            try await repositoryContext.perform(schedule: .immediate) {
                repositoryContext.transactionAuthor = author
                _ = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            withKnownIssue {
                try verify(transactionAuthor: "WRONG", timeStamp: date)
            }
        }

        @Test
        func verifyHistory_Failure_WrongDate() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            let author: String = #function

            try await repositoryContext.perform(schedule: .immediate) {
                repositoryContext.transactionAuthor = author
                _ = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            let date = Date.now

            withKnownIssue {
                try verify(transactionAuthor: author, timeStamp: date)
            }
        }

        @Test
        func verifyHistoryDoesNotExist_Success_Date() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            try await repositoryContext.perform(schedule: .immediate) {
                _ = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            let date = Date.now

            try verifyDoesNotExist(transactionAuthor: nil, timeStamp: date)
        }

        @Test
        func verifyHistoryDoesNotExist_Success_Author() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            let author: String = #function
            let date = Date.now

            try await repositoryContext.perform(schedule: .immediate) {
                repositoryContext.transactionAuthor = author
                _ = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            try verifyDoesNotExist(transactionAuthor: "WRONG_AUTHOR", timeStamp: date)
        }

        @Test
        func verifyHistoryDoesNotExist_Failure_Date() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            let date = Date.now

            try await repositoryContext.perform(schedule: .immediate) {
                _ = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            withKnownIssue {
                try verifyDoesNotExist(transactionAuthor: nil, timeStamp: date)
            }
        }

        @Test
        func verifyHistoryDoesNotExist_Failure_Author() async throws {
            let modelType = FetchableModel_UuidId.self
            let _value = modelType.seeded(1)

            let author: String = #function
            let date = Date.now

            try await repositoryContext.perform(schedule: .immediate) {
                repositoryContext.transactionAuthor = author
                _ = try _value.asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            withKnownIssue {
                try verifyDoesNotExist(transactionAuthor: author, timeStamp: date)
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
