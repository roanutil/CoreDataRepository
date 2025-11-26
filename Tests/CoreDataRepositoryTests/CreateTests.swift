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

        @Test(arguments: [false, true])
        func create_Fetchable_Success(inTransaction: Bool) async throws {
            let modelType = FetchableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let value = if inTransaction {
                try await repository.withTransaction(transactionAuthor: transactionAuthor) { _ in
                    try await repository
                        .create(_value).get()
                }
            } else {
                try await repository
                    .create(_value, transactionAuthor: transactionAuthor).get()
            }

            expectNoDifference(value, _value)

            try await verify(value)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test(arguments: [false, true])
        func create_Fetchable_Failure(inTransaction: Bool) async throws {
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

            if inTransaction {
                try await withKnownIssue {
                    _ = try await repository.withTransaction { _ in
                        await repository
                            .create(_value)
                    }
                } matching: { issue in
                    guard let error = issue.error as? CoreDataError else {
                        return false
                    }
                    switch error {
                    case let .cocoa(cocoaError):
                        let nsError = cocoaError as NSError
                        return nsError.code == 133_021
                            && nsError.domain == "NSCocoaErrorDomain"
                    default:
                        return false
                    }
                }
            } else {
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
        }

        @Test(arguments: [false, true])
        func create_Identifiable_Success(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let value = if inTransaction {
                try await repository.withTransaction(transactionAuthor: transactionAuthor) { _ in
                    try await repository
                        .create(_value, transactionAuthor: transactionAuthor).get()
                }
            } else {
                try await repository
                    .create(_value, transactionAuthor: transactionAuthor).get()
            }

            expectNoDifference(value, _value)

            try await verify(value)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test(arguments: [false, true])
        func create_Identifiable_Failure(inTransaction: Bool) async throws {
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

            if inTransaction {
                try await withKnownIssue {
                    _ = try await repository.withTransaction { _ in
                        await repository
                            .create(_value)
                    }
                } matching: { issue in
                    guard let error = issue.error as? CoreDataError else {
                        return false
                    }
                    switch error {
                    case let .cocoa(cocoaError):
                        let nsError = cocoaError as NSError
                        return nsError.code == 133_021
                            && nsError.domain == "NSCocoaErrorDomain"
                    default:
                        return false
                    }
                }
            } else {
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
        }

        @Test(arguments: [false, true])
        func create_ManagedIdReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let value = if inTransaction {
                try await repository.withTransaction(transactionAuthor: transactionAuthor) { _ in
                    try await repository
                        .create(_value, transactionAuthor: transactionAuthor).get()
                }
            } else {
                try await repository
                    .create(_value, transactionAuthor: transactionAuthor).get()
            }
            expectNoDifference(value.removingManagedId(), _value)

            try await verify(value)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test(arguments: [false, true])
        func create_ManagedIdReferencable_Failure(inTransaction: Bool) async throws {
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

            if inTransaction {
                try await withKnownIssue {
                    _ = try await repository.withTransaction { _ in
                        await repository
                            .create(_value)
                    }
                } matching: { issue in
                    guard let error = issue.error as? CoreDataError else {
                        return false
                    }
                    switch error {
                    case let .cocoa(cocoaError):
                        let nsError = cocoaError as NSError
                        return nsError.code == 133_021
                            && nsError.domain == "NSCocoaErrorDomain"
                    default:
                        return false
                    }
                }
            }
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

        @Test(arguments: [false, true])
        func create_ManagedIdUrlReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
            let historyTimeStamp = Date()
            let transactionAuthor: String = #function
            let _value = modelType.seeded(1)
            let value = if inTransaction {
                try await repository.withTransaction(transactionAuthor: transactionAuthor) { _ in
                    try await repository
                        .create(_value, transactionAuthor: transactionAuthor).get()
                }
            } else {
                try await repository
                    .create(_value, transactionAuthor: transactionAuthor).get()
            }
            expectNoDifference(value.removingManagedIdUrl(), _value)

            try await verify(value)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test(arguments: [false, true])
        func create_ManagedIdUrlReferencable_Failure(inTransaction: Bool) async throws {
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

            if inTransaction {
                try await withKnownIssue {
                    _ = try await repository.withTransaction { _ in
                        await repository
                            .create(_value)
                    }
                } matching: { issue in
                    guard let error = issue.error as? CoreDataError else {
                        return false
                    }
                    switch error {
                    case let .cocoa(cocoaError):
                        let nsError = cocoaError as NSError
                        return nsError.code == 133_021
                            && nsError.domain == "NSCocoaErrorDomain"
                    default:
                        return false
                    }
                }
            } else {
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
