// BatchRequestTests.swift
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
    struct BatchRequestTests: CoreDataTestSuite, Sendable {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        nonisolated(unsafe) let values: [[String: Any]] = [
            ManagedIdUrlModel_UuidId.seeded(1).asDict,
            ManagedIdUrlModel_UuidId.seeded(2).asDict,
            ManagedIdUrlModel_UuidId.seeded(3).asDict,
            ManagedIdUrlModel_UuidId.seeded(4).asDict,
            ManagedIdUrlModel_UuidId.seeded(5).asDict,
        ]
        nonisolated(unsafe) let failureInsertMovies: [[String: Any]] = [
            ["id": "A", "title": 1, "releaseDate": "A"],
            ["id": "B", "title": 2, "releaseDate": "B"],
            ["id": "C", "title": 3, "releaseDate": "C"],
            ["id": "D", "title": 4, "releaseDate": "D"],
            ["id": "E", "title": 5, "releaseDate": "E"],
        ]
        nonisolated(unsafe) let failureCreateMovies: [[String: Any]] = [
            ["id": UUID(uniform: "A"), "title": "A", "releaseDate": Date()],
            ["id": UUID(uniform: "A"), "title": "B", "releaseDate": Date()],
            ["id": UUID(uniform: "A"), "title": "C", "releaseDate": Date()],
            ["id": UUID(uniform: "A"), "title": "D", "releaseDate": Date()],
            ["id": UUID(uniform: "A"), "title": "E", "releaseDate": Date()],
        ]

        func mapDictToManagedModel(_ dict: [String: Any]) throws -> ManagedModel_UuidId {
            try mapDictToUnmanagedModel(dict).asManagedModel(in: repositoryContext)
        }

        func mapDictToUnmanagedModel(_ dict: [String: Any]) throws -> ManagedIdUrlModel_UuidId {
            let id = try #require(dict["id"] as? UUID)
            let bool = try #require(dict["bool"] as? Bool)
            let date = try #require(dict["date"] as? Date)
            let decimal = try #require(dict["decimal"] as? Decimal)
            let double = try #require(dict["double"] as? Double)
            let float = try #require(dict["float"] as? Float)
            let int = try #require(dict["int"] as? Int)
            let string = try #require(dict["string"] as? String)
            let uuid = try #require(dict["uuid"] as? UUID)

            return .init(
                bool: bool,
                date: date,
                decimal: decimal,
                double: double,
                float: float,
                id: id,
                int: int,
                managedIdUrl: nil,
                string: string,
                uuid: uuid
            )
        }

        @Test(arguments: [false, true])
        func insertSuccess(inTransaction: Bool) async throws {
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: ManagedIdUrlModel_UuidId.managedFetchRequest())
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
            }

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            let request = try NSBatchInsertRequest(
                entityName: #require(ManagedModel_UuidId.entity().name),
                objects: values
            )
            let result = if inTransaction {
                try await repository.withTransaction(transactionAuthor: transactionAuthor) { _ in
                    await repository
                        .insert(request)
                }
            } else {
                await repository
                    .insert(request, transactionAuthor: transactionAuthor)
            }

            switch result {
            case .success:
                break
            case .failure:
                Issue.record("Not expecting a failure result")
            }

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(ManagedIdUrlModel_UuidId.managedFetchRequest())
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["1", "2", "3", "4", "5"],
                    "Inserted titles should match expectation"
                )
            }

            // Transaction author refuses to be applied when going through a transaction. Need to investigate further.
            if inTransaction {
                withKnownIssue {
                    try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
                }
            } else {
                try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
            }
        }

        @Test(arguments: [false, true])
        func insertFailure(inTransaction: Bool) async throws {
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: ManagedIdUrlModel_UuidId.managedFetchRequest())
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
            }

            let request = try NSBatchInsertRequest(
                entityName: #require(ManagedModel_UuidId.entity().name),
                objects: failureInsertMovies
            )
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository.insert(request)
                }
            } else {
                await repository.insert(request)
            }

            switch result {
            case .success:
                Issue.record("Not expecting a success result")
            case .failure:
                break
            }

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(ManagedIdUrlModel_UuidId.managedFetchRequest())
                expectNoDifference(data.map(\.string).sorted(), [], "There should be no inserted values.")
            }
        }

        @Test(arguments: [false, true])
        func updateSuccess(inTransaction: Bool) async throws {
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: ManagedIdUrlModel_UuidId.managedFetchRequest())
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

                _ = try values
                    .map(mapDictToManagedModel(_:))
                try repositoryContext.save()
            }

            let predicate = NSPredicate(value: true)
            let request = try NSBatchUpdateRequest(entityName: #require(ManagedModel_UuidId.entity().name))
            request.predicate = predicate
            request.propertiesToUpdate = ["string": "Updated!", "int": 1]

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            _ = if inTransaction {
                try await repository.withTransaction(transactionAuthor: transactionAuthor) { _ in
                    await repository
                        .update(request)
                }
            } else {
                await repository
                    .update(request, transactionAuthor: transactionAuthor)
            }

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(ManagedIdUrlModel_UuidId.managedFetchRequest())
                expectNoDifference(
                    data.map(\.string).sorted(),
                    ["Updated!", "Updated!", "Updated!", "Updated!", "Updated!"],
                    "Updated titles should match request"
                )
            }
            // Transaction author refuses to be applied when going through a transaction. Need to investigate further.
            if inTransaction {
                withKnownIssue {
                    try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
                }
            } else {
                try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
            }
        }

        @Test(arguments: [false, true])
        func deleteSuccess(inTransaction: Bool) async throws {
            try await repositoryContext.perform {
                let count = try repositoryContext.count(for: ManagedIdUrlModel_UuidId.managedFetchRequest())
                expectNoDifference(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

                _ = try values
                    .map(mapDictToManagedModel(_:))
                try repositoryContext.save()
            }

            let request =
                try NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: #require(
                    ManagedModel_UuidId
                        .entity().name
                )))

            let historyTimeStamp = Date()
            let transactionAuthor: String = #function

            _ = if inTransaction {
                try await repository.withTransaction(transactionAuthor: transactionAuthor) { _ in
                    await repository
                        .delete(request, transactionAuthor: transactionAuthor)
                }
            } else {
                await repository
                    .delete(request, transactionAuthor: transactionAuthor)
            }

            try await repositoryContext.perform {
                let data = try repositoryContext.fetch(ManagedIdUrlModel_UuidId.managedFetchRequest())
                expectNoDifference(data.map(\.string).sorted(), [], "There should be no remaining values.")
            }
            // Transaction author refuses to be applied when going through a transaction. Need to investigate further.
            if inTransaction {
                withKnownIssue {
                    try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
                }
            } else {
                try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
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
