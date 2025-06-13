// Delete_BatchTests.swift
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
    struct Delete_BatchTests: CoreDataTestSuite {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        // MARK: Non Atomic

        @Test
        func delete_Identifiable_Success() async throws {
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

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            let (successful, failed) = await repository
                .delete(existingValues, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func delete_Identifiable_Failure() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]
            let (successful, failed) = await repository
                .delete(_values)

            expectNoDifference(successful.count, 0)
            expectNoDifference(failed.count, _values.count)
        }

        @Test
        func delete_ManagedIdReferencable_Success() async throws {
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

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            let (successful, failed) = await repository
                .delete(existingValues, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
            for value in existingValues {
                try await verifyDoesNotExist(value)
            }
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func delete_ManagedIdReferencable_Failure() async throws {
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

            let (successful, failed) = await repository
                .delete(_values)

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)
            for value in _values[1 ... 4] {
                try await verifyDoesNotExist(value)
            }
        }

        @Test
        func delete_ManagedIdReferencable_NoManagedId_Failure() async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let (successful, failed) = await repository
                .delete(_values)

            expectNoDifference(successful.count, 0)
            expectNoDifference(failed.count, _values.count)
        }

        @Test
        func delete_ManagedId_Success() async throws {
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

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            let (successful, failed) = await repository
                .delete(existingValues.compactMap(\.managedId), transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
            for value in existingValues {
                try await verifyDoesNotExist(value)
            }
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func delete_ManagedId_Failure() async throws {
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

            let (successful, failed) = try await repository
                .delete(_values.map { try #require($0.managedId) })

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)
            for value in _values[1 ... 4] {
                try await verifyDoesNotExist(value)
            }
        }

        @Test
        func delete_ManagedIdUrlReferencable_Success() async throws {
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

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            let (successful, failed) = await repository
                .delete(existingValues, transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
            for value in existingValues {
                try await verifyDoesNotExist(value)
            }
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func delete_ManagedIdUrlReferencable_Failure() async throws {
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

            let (successful, failed) = await repository
                .delete(_values)

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)
            for value in _values {
                try await verifyDoesNotExist(value)
            }
        }

        @Test
        func delete_ManagedIdUrlReferencable_NoManagedIdUrl_Failure() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let (successful, failed) = await repository
                .delete(_values)

            expectNoDifference(successful.count, 0)
            expectNoDifference(failed.count, _values.count)
        }

        @Test
        func delete_ManagedIdUrl_Success() async throws {
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

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            let (successful, failed) = await repository
                .delete(existingValues.compactMap(\.managedIdUrl), transactionAuthor: transactionAuthor)

            expectNoDifference(successful.count, _values.count)
            expectNoDifference(failed.count, 0)
            for value in existingValues {
                try await verifyDoesNotExist(value)
            }
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func delete_ManagedIdUrl_Failure() async throws {
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

            let (successful, failed) = try await repository
                .delete(_values.map { try #require($0.managedIdUrl) })

            expectNoDifference(successful.count, _values.count - 1)
            expectNoDifference(failed.count, 1)
            for value in _values[1 ... 4] {
                try await verifyDoesNotExist(value)
            }
        }

        // MARK: Atomic

        @Test
        func deleteAtomically_Identifiable_Success() async throws {
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

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            try await repository
                .deleteAtomically(existingValues, transactionAuthor: transactionAuthor).get()

            for value in existingValues {
                try await verifyDoesNotExist(value)
            }
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func deleteAtomically_Identifiable_Failure() async throws {
            let modelType = IdentifiableModel_UuidId.self
            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]
            let result = await repository
                .deleteAtomically(_values)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noMatchFoundWhenReadingItem):
                break
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func deleteAtomically_ManagedIdReferencable_Success() async throws {
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

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            try await repository
                .deleteAtomically(existingValues, transactionAuthor: transactionAuthor).get()

            for value in existingValues {
                try await verifyDoesNotExist(value)
            }
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func deleteAtomically_ManagedIdReferencable_Failure() async throws {
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

            let result = await repository
                .deleteAtomically(_values)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }

            for value in _values[1 ... 4] {
                try await verify(value)
            }
            try await verifyDoesNotExist(_values[0])
        }

        @Test
        func deleteAtomically_ManagedIdReferencable_NoManagedId_Failure() async throws {
            let modelType = ManagedIdModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let result = await repository
                .deleteAtomically(_values)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noObjectIdOnItem):
                break
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func deleteAtomically_ManagedId_Success() async throws {
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

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            try await repository
                .deleteAtomically(existingValues.compactMap(\.managedId), transactionAuthor: transactionAuthor).get()

            for value in existingValues {
                try await verifyDoesNotExist(value)
            }
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func deleteAtomically_ManagedId_Failure() async throws {
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

            let result = try await repository
                .deleteAtomically(_values.map { try #require($0.managedId) })

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }

            for value in _values[1 ... 4] {
                try await verify(value)
            }
            try await verifyDoesNotExist(_values[0])
        }

        @Test
        func deleteAtomically_ManagedIdUrlReferencable_Success() async throws {
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

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            try await repository
                .deleteAtomically(existingValues, transactionAuthor: transactionAuthor).get()

            for value in existingValues {
                try await verifyDoesNotExist(value)
            }
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func deleteAtomically_ManagedIdUrlReferencable_Failure() async throws {
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

            let result = await repository
                .deleteAtomically(_values)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }

            for value in _values[1 ... 4] {
                try await verify(value)
            }
            try await verifyDoesNotExist(_values[0])
        }

        @Test
        func deleteAtomically_ManagedIdUrlReferencable_NoManagedIdUrl_Failure() async throws {
            let modelType = ManagedIdUrlModel_UuidId.self

            let _values = [
                modelType.seeded(1),
                modelType.seeded(2),
                modelType.seeded(3),
                modelType.seeded(4),
                modelType.seeded(5),
            ]

            let result = await repository
                .deleteAtomically(_values)

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case .failure(.noUrlOnItemToMapToObjectId):
                break
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func deleteAtomically_ManagedIdUrl_Success() async throws {
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

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            try await repository
                .deleteAtomically(existingValues.compactMap(\.managedIdUrl), transactionAuthor: transactionAuthor).get()

            for value in existingValues {
                try await verifyDoesNotExist(value)
            }
            try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
        }

        @Test
        func deleteAtomically_ManagedIdUrl_Failure() async throws {
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

            let result = try await repository
                .deleteAtomically(_values.map { try #require($0.managedIdUrl) })

            switch result {
            case .success:
                Issue.record("Not expecting success")
            case let .failure(.cocoa(cocoaError)):
                expectNoDifference(cocoaError.code, .managedObjectReferentialIntegrity)
            case let .failure(error):
                Issue.record("Unexpected error: \(error)")
            }

            for value in _values[1 ... 4] {
                try await verify(value)
            }
            try await verifyDoesNotExist(_values[0])
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
