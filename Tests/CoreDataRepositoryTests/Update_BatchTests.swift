// Update_BatchTests.swift
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
    struct Update_BatchTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        // MARK: Non Atomic

        @Test(arguments: [false, true])
        func update_Identifiable_Success(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]
            var existingValues = try await repositoryContext.perform(schedule: .immediate) {
                let manageds = try _values.map { try $0.asManagedModel(in: repositoryContext) }
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try manageds.map { try modelType.init(managed: $0) }
            }
            expectNoDifference(existingValues, _values)

            for value in existingValues {
                try await verify(value)
            }

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            existingValues = existingValues.map { value in
                var value = value
                value.int += 1
                return value
            }

            let (successful, failed) = if inTransaction {
                try await repository.withTransaction(transactionAuthor: transactionAuthor) { _ in
                    await repository
                        .update(existingValues)
                }
            } else {
                await repository
                    .update(existingValues, transactionAuthor: transactionAuthor)
            }

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
            for value in successful {
                try await verify(value)
            }
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test(arguments: [false, true])
        func update_Identifiable_Failure(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]
            let (successful, failed) = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .update(_values)
                }
            } else {
                await repository
                    .update(_values)
            }

            expectNoDifference(successful.count, 0)
            expectNoDifference(failed.count, _values.count)
        }

        // MARK: Atomic

        @Test(arguments: [false, true])
        func updateAtomically_Identifiable_Success(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]
            let existingValues = try await repositoryContext.perform(schedule: .immediate) {
                let manageds = try _values.map { try $0.asManagedModel(in: repositoryContext) }
                try repositoryContext.save()
                try repositoryContext.parent?.save()
                return try manageds.map { try modelType.init(managed: $0) }
            }
            expectNoDifference(existingValues, _values)

            for value in existingValues {
                try await verify(value)
            }

            let updatedValues = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .updateAtomically(existingValues).get()
                }
            } else {
                try await repository
                    .updateAtomically(existingValues).get()
            }

            for value in updatedValues {
                try await verify(value)
            }
        }

        @Test(arguments: [false, true])
        func updateAtomically_Identifiable_Failure(inTransaction: Bool) async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .updateAtomically(_values)
                }
            } else {
                await repository
                    .updateAtomically(_values)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(
                .noMatchFoundWhenReadingItem(
                    description: "\(modelType) -- id: \(modelType.seeded(1).unmanagedId.uuidString)"
                )
            ):
                break
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
