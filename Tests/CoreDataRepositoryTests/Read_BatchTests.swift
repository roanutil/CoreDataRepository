// Read_BatchTests.swift
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
    struct Read_BatchTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        // MARK: Non Atomic

        @Test(arguments: [false, true])
        func read_Identifiable_Success(inTransaction: Bool) async throws {
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

            let (successful, failed) = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(existingValues)
                }
            } else {
                await repository
                    .read(existingValues)
            }

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
        }

        @Test(arguments: [false, true])
        func read_Identifiable_Failure(inTransaction: Bool) async throws {
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
                        .read(_values)
                }
            } else {
                await repository
                    .read(_values)
            }

            expectNoDifference(successful.count, 0)
            expectNoDifference(failed.count, _values.count)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
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
            expectNoDifference(existingValues.map { $0.removingManagedId() }, _values)

            for value in existingValues {
                try await verify(value)
            }

            let (successful, failed) = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(existingValues)
                }
            } else {
                await repository
                    .read(existingValues)
            }

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdReferencable_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _values = try await repositoryContext.perform(schedule: .immediate) {
                let manageds = try [
                    modelType.seeded(1),
                    modelType.seeded(2),
                    modelType.seeded(3),
                    modelType.seeded(4),
                    modelType.seeded(5),
                ].map { try $0.asManagedModel(in: repositoryContext) }
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: manageds)
                let values = try manageds.map { try modelType.init(managed: $0) }

                repositoryContext.delete(manageds[0])
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return values
            }

            let (successful, failed) = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(_values)
                }
            } else {
                await repository
                    .read(_values)
            }

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdReferencable_NoManagedId_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self

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
                        .read(_values)
                }
            } else {
                await repository
                    .read(_values)
            }

            expectNoDifference(successful.count, 0)
            expectNoDifference(failed.count, _values.count)
        }

        @Test(arguments: [false, true])
        func read_ManagedId_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
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
            expectNoDifference(existingValues.map { $0.removingManagedId() }, _values)

            for value in existingValues {
                try await verify(value)
            }

            let (successful, failed) = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(existingValues.compactMap(\.managedId), as: modelType)
                }
            } else {
                await repository
                    .read(existingValues.compactMap(\.managedId), as: modelType)
            }

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
        }

        @Test(arguments: [false, true])
        func read_ManagedId_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _values = try await repositoryContext.perform(schedule: .immediate) {
                let manageds = try [
                    modelType.seeded(1),
                    modelType.seeded(2),
                    modelType.seeded(3),
                    modelType.seeded(4),
                    modelType.seeded(5),
                ].map { try $0.asManagedModel(in: repositoryContext) }
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: manageds)
                let values = try manageds.map { try modelType.init(managed: $0) }

                repositoryContext.delete(manageds[0])
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return values
            }

            for value in _values[1 ... 4] {
                try await verify(value)
            }
            try await verifyDoesNotExist(_values[0])

            let (successful, failed) = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .read(_values.map { try #require($0.managedId) }, as: modelType)
                }
            } else {
                try await repository
                    .read(_values.map { try #require($0.managedId) }, as: modelType)
            }

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdUrlReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
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
            expectNoDifference(existingValues.map { $0.removingManagedIdUrl() }, _values)

            for value in existingValues {
                try await verify(value)
            }

            let (successful, failed) = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(existingValues)
                }
            } else {
                await repository
                    .read(existingValues)
            }

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdUrlReferencable_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _values = try await repositoryContext.perform(schedule: .immediate) {
                let manageds = try [
                    modelType.seeded(1),
                    modelType.seeded(2),
                    modelType.seeded(3),
                    modelType.seeded(4),
                    modelType.seeded(5),
                ].map { try $0.asManagedModel(in: repositoryContext) }
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: manageds)
                let values = try manageds.map { try modelType.init(managed: $0) }

                repositoryContext.delete(manageds[0])
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return values
            }

            let (successful, failed) = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(_values)
                }
            } else {
                await repository
                    .read(_values)
            }

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdUrlReferencable_NoManagedIdUrl_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

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
                        .read(_values)
                }
            } else {
                await repository
                    .read(_values)
            }

            expectNoDifference(successful.count, 0)
            expectNoDifference(failed.count, _values.count)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdUrl_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
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
            expectNoDifference(existingValues.map { $0.removingManagedIdUrl() }, _values)

            for value in existingValues {
                try await verify(value)
            }

            let (successful, failed) = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .read(existingValues.compactMap(\.managedIdUrl), as: modelType)
                }
            } else {
                await repository
                    .read(existingValues.compactMap(\.managedIdUrl), as: modelType)
            }

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
        }

        @Test(arguments: [false, true])
        func read_ManagedIdUrl_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _values = try await repositoryContext.perform(schedule: .immediate) {
                let manageds = try [
                    modelType.seeded(1),
                    modelType.seeded(2),
                    modelType.seeded(3),
                    modelType.seeded(4),
                    modelType.seeded(5),
                ].map { try $0.asManagedModel(in: repositoryContext) }
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: manageds)
                let values = try manageds.map { try modelType.init(managed: $0) }

                repositoryContext.delete(manageds[0])
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return values
            }

            let (successful, failed) = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .read(_values.map { try #require($0.managedIdUrl) }, as: modelType)
                }
            } else {
                try await repository
                    .read(_values.map { try #require($0.managedIdUrl) }, as: modelType)
            }

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)
        }

        // MARK: Atomic

        @Test(arguments: [false, true])
        func readAtomically_Identifiable_Success(inTransaction: Bool) async throws {
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

            let values = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .readAtomically(existingValues).get()
                }
            } else {
                try await repository
                    .readAtomically(existingValues).get()
            }

            expectNoDifference(values, existingValues)
        }

        @Test(arguments: [false, true])
        func readAtomically_Identifiable_Failure(inTransaction: Bool) async throws {
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
                        .readAtomically(_values)
                }
            } else {
                await repository
                    .readAtomically(_values)
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

        @Test(arguments: [false, true])
        func readAtomically_ManagedIdReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
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
            expectNoDifference(existingValues.map { $0.removingManagedId() }, _values)

            for value in existingValues {
                try await verify(value)
            }

            let values = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .readAtomically(existingValues).get()
                }
            } else {
                try await repository
                    .readAtomically(existingValues).get()
            }

            expectNoDifference(values, existingValues)
        }

        @Test(arguments: [false, true])
        func readAtomically_ManagedIdReferencable_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _values = try await repositoryContext.perform(schedule: .immediate) {
                let manageds = try [
                    modelType.seeded(1),
                    modelType.seeded(2),
                    modelType.seeded(3),
                    modelType.seeded(4),
                    modelType.seeded(5),
                ].map { try $0.asManagedModel(in: repositoryContext) }
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: manageds)
                let values = try manageds.map { try modelType.init(managed: $0) }

                repositoryContext.delete(manageds[0])
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return values
            }

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .readAtomically(_values)
                }
            } else {
                await repository
                    .readAtomically(_values)
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
        func readAtomically_ManagedIdReferencable_NoManagedId_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self

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
                        .readAtomically(_values)
                }
            } else {
                await repository
                    .readAtomically(_values)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noObjectIdOnItem(description: "\(modelType)")):
                break
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test(arguments: [false, true])
        func readAtomically_ManagedId_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self
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
            expectNoDifference(existingValues.map { $0.removingManagedId() }, _values)

            for value in existingValues {
                try await verify(value)
            }

            let values = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .readAtomically(existingValues.compactMap(\.managedId), as: modelType).get()
                }
            } else {
                try await repository
                    .readAtomically(existingValues.compactMap(\.managedId), as: modelType).get()
            }

            expectNoDifference(values, existingValues)
        }

        @Test(arguments: [false, true])
        func readAtomically_ManagedId_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _values = try await repositoryContext.perform(schedule: .immediate) {
                let manageds = try [
                    modelType.seeded(1),
                    modelType.seeded(2),
                    modelType.seeded(3),
                    modelType.seeded(4),
                    modelType.seeded(5),
                ].map { try $0.asManagedModel(in: repositoryContext) }
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: manageds)
                let values = try manageds.map { try modelType.init(managed: $0) }

                repositoryContext.delete(manageds[0])
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return values
            }

            for value in _values[1 ... 4] {
                try await verify(value)
            }
            try await verifyDoesNotExist(_values[0])

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .readAtomically(_values.map { try #require($0.managedId) }, as: modelType)
                }
            } else {
                try await repository
                    .readAtomically(_values.map { try #require($0.managedId) }, as: modelType)
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
        func readAtomically_ManagedIdUrlReferencable_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
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
            expectNoDifference(existingValues.map { $0.removingManagedIdUrl() }, _values)

            for value in existingValues {
                try await verify(value)
            }

            let values = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .readAtomically(existingValues).get()
                }
            } else {
                try await repository
                    .readAtomically(existingValues).get()
            }

            expectNoDifference(values, existingValues)
        }

        @Test(arguments: [false, true])
        func readAtomically_ManagedIdUrlReferencable_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _values = try await repositoryContext.perform(schedule: .immediate) {
                let manageds = try [
                    modelType.seeded(1),
                    modelType.seeded(2),
                    modelType.seeded(3),
                    modelType.seeded(4),
                    modelType.seeded(5),
                ].map { try $0.asManagedModel(in: repositoryContext) }
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: manageds)
                let values = try manageds.map { try modelType.init(managed: $0) }

                repositoryContext.delete(manageds[0])
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return values
            }

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .readAtomically(_values)
                }
            } else {
                await repository
                    .readAtomically(_values)
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
        func readAtomically_ManagedIdUrlReferencable_NoManagedIdUrl_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

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
                        .readAtomically(_values)
                }
            } else {
                await repository
                    .readAtomically(_values)
            }

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noUrlOnItemToMapToObjectId(description: "\(modelType)")):
                break
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test(arguments: [false, true])
        func readAtomically_ManagedIdUrl_Success(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self
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
            expectNoDifference(existingValues.map { $0.removingManagedIdUrl() }, _values)

            for value in existingValues {
                try await verify(value)
            }

            let values = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .readAtomically(existingValues.compactMap(\.managedIdUrl), as: modelType).get()
                }
            } else {
                try await repository
                    .readAtomically(existingValues.compactMap(\.managedIdUrl), as: modelType).get()
            }

            expectNoDifference(values, existingValues)
        }

        @Test(arguments: [false, true])
        func readAtomically_ManagedIdUrl_Failure(inTransaction: Bool) async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _values = try await repositoryContext.perform(schedule: .immediate) {
                let manageds = try [
                    modelType.seeded(1),
                    modelType.seeded(2),
                    modelType.seeded(3),
                    modelType.seeded(4),
                    modelType.seeded(5),
                ].map { try $0.asManagedModel(in: repositoryContext) }
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                try repositoryContext.obtainPermanentIDs(for: manageds)
                let values = try manageds.map { try modelType.init(managed: $0) }

                repositoryContext.delete(manageds[0])
                try repositoryContext.save()
                try repositoryContext.parent?.save()

                return values
            }

            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository
                        .readAtomically(_values.map { try #require($0.managedIdUrl) }, as: modelType)
                }
            } else {
                try await repository
                    .readAtomically(_values.map { try #require($0.managedIdUrl) }, as: modelType)
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
