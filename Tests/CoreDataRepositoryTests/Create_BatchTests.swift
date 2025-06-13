// Create_BatchTests.swift
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
    struct Create_BatchTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        @Test
        func create_Fetchable_Success() async throws {
            let modelType = FetchableModel_UuidId.self

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
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

            let (successful, failed) = await repository
                .create(_values, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)

            for value in successful {
                try await verify(value)
            }

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_Fetchable_Failure() async throws {
            let modelType = FetchableModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

                _ = try _values[0].asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            let (successful, failed) = await repository
                .create(_values, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)

            for value in successful {
                try await verify(value)
            }

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_Identifiable_Success() async throws {
            let modelType = IdentifiableModel_UuidId.self

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
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

            let (successful, failed) = await repository
                .create(_values, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)

            for value in successful {
                try await verify(value)
            }

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_Identifiable_Failure() async throws {
            let modelType = IdentifiableModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

                _ = try _values[0].asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            let (successful, failed) = await repository
                .create(_values, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)

            for value in successful {
                try await verify(value)
            }

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_ManagedIdUrlReferencable_Success() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
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

            let (successful, failed) = await repository
                .create(_values, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)

            for value in successful {
                try await verify(value)
            }

            expectNoDifference(successful.map { $0.removingManagedIdUrl() }.sorted(), _values)

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_ManagedIdUrlReferencable_Failure() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

                _ = try _values[0].asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            let (successful, failed) = await repository
                .create(_values, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)

            for value in successful {
                try await verify(value)
            }

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_ManagedIdReferencable_Success() async throws {
            let modelType = ManagedIdModel_UuidId.self

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
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

            let (successful, failed) = await repository
                .create(_values, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)

            for value in successful {
                try await verify(value)
            }

            expectNoDifference(successful.map { $0.removingManagedId() }.sorted(), _values)

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func create_ManagedIdReferencable_Failure() async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

                _ = try _values[0].asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
            }

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            let (successful, failed) = await repository
                .create(_values, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)

            for value in successful {
                try await verify(value)
            }

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func createAtomically_Fetchable_Success() async throws {
            let modelType = FetchableModel_UuidId.self

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
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

            let createdValues = try await repository
                .createAtomically(_values, transactionAuthor: transactionAuthor).get()

            expectNoDifference(createdValues.count, _values.count)

            for value in createdValues {
                try await verify(value)
            }

            expectNoDifference(createdValues, _values)

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func createAtomically_Fetchable_Failure() async throws {
            let modelType = FetchableModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let fetchRequest = modelType.managedFetchRequest()
            let existingValue = try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

                let value = try _values[0].asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return value
            }
            try await verify(mapInContext(existingValue, transform: modelType.init(managed:)))

            let result = await repository
                .createAtomically(_values)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectConstraintMerge)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }

            for value in _values[1 ... 4] {
                try await verifyDoesNotExist(value)
            }
        }

        @Test
        func createAtomically_Identifiable_Success() async throws {
            let modelType = IdentifiableModel_UuidId.self

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
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

            let createdValues = try await repository
                .createAtomically(_values, transactionAuthor: transactionAuthor).get()

            expectNoDifference(createdValues.count, _values.count)

            for value in createdValues {
                try await verify(value)
            }

            expectNoDifference(createdValues, _values)

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func createAtomically_Identifiable_Failure() async throws {
            let modelType = IdentifiableModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let fetchRequest = modelType.managedFetchRequest()
            let existingValue = try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

                let value = try _values[0].asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return value
            }
            try await verify(mapInContext(existingValue, transform: modelType.init(managed:)))

            let result = await repository
                .createAtomically(_values)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectConstraintMerge)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }

            for value in _values[1 ... 4] {
                try await verifyDoesNotExist(value)
            }
        }

        @Test
        func createAtomically_ManagedIdUrlReferencable_Success() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
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

            let createdValues = try await repository
                .createAtomically(_values, transactionAuthor: transactionAuthor).get()

            expectNoDifference(createdValues.count, _values.count)

            for value in createdValues {
                try await verify(value)
            }

            expectNoDifference(createdValues.map { $0.removingManagedIdUrl() }, _values)

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func createAtomically_ManagedIdUrlReferencable_Failure() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let fetchRequest = modelType.managedFetchRequest()
            let existingValue = try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

                let value = try _values[0].asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return value
            }
            try await verify(mapInContext(existingValue, transform: modelType.init(managed:)))

            let result = await repository
                .createAtomically(_values)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectConstraintMerge)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }

            for value in _values[1 ... 4] {
                try await verifyDoesNotExist(value)
            }
        }

        @Test
        func createAtomically_ManagedIdReferencable_Success() async throws {
            let modelType = ManagedIdModel_UuidId.self

            let fetchRequest = modelType.managedFetchRequest()
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
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

            let createdValues = try await repository
                .createAtomically(_values, transactionAuthor: transactionAuthor).get()

            expectNoDifference(createdValues.count, _values.count)

            for value in createdValues {
                try await verify(value)
            }

            expectNoDifference(createdValues.map { $0.removingManagedId() }, _values)

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(fetchRequest)
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func createAtomically_ManagedIdReferencable_Failure() async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let fetchRequest = modelType.managedFetchRequest()
            let existingValue = try await repositoryContext.perform {
                let count = try repositoryContext.count(for: fetchRequest)
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

                let value = try _values[0].asManagedModel(in: repositoryContext)
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return value
            }
            try await verify(mapInContext(existingValue, transform: modelType.init(managed:)))

            let result = await repository
                .createAtomically(_values)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectConstraintMerge)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }

            for value in _values[1 ... 4] {
                try await verifyDoesNotExist(value)
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
