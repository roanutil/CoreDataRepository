// BatchRequestTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import CustomDump
import Internal
import XCTest

final class BatchRequestTests: CoreDataXCTestCase {
    let values: [[String: Any]] = [
        ManagedIdUrlModel_UuidId.seeded(1).asDict,
        ManagedIdUrlModel_UuidId.seeded(2).asDict,
        ManagedIdUrlModel_UuidId.seeded(3).asDict,
        ManagedIdUrlModel_UuidId.seeded(4).asDict,
        ManagedIdUrlModel_UuidId.seeded(5).asDict,
    ]
    let failureInsertMovies: [[String: Any]] = [
        ["id": "A", "title": 1, "releaseDate": "A"],
        ["id": "B", "title": 2, "releaseDate": "B"],
        ["id": "C", "title": 3, "releaseDate": "C"],
        ["id": "D", "title": 4, "releaseDate": "D"],
        ["id": "E", "title": 5, "releaseDate": "E"],
    ]
    let failureCreateMovies: [[String: Any]] = [
        ["id": UUID(uniform: "A"), "title": "A", "releaseDate": Date()],
        ["id": UUID(uniform: "A"), "title": "B", "releaseDate": Date()],
        ["id": UUID(uniform: "A"), "title": "C", "releaseDate": Date()],
        ["id": UUID(uniform: "A"), "title": "D", "releaseDate": Date()],
        ["id": UUID(uniform: "A"), "title": "E", "releaseDate": Date()],
    ]

    func mapDictToManagedModel(_ dict: [String: Any]) throws -> ManagedModel_UuidId {
        try mapDictToUnmanagedModel(dict).asManagedModel(in: repositoryContext())
    }

    func mapDictToUnmanagedModel(_ dict: [String: Any]) throws -> ManagedIdUrlModel_UuidId {
        let id = try XCTUnwrap(dict["id"] as? UUID)
        let bool = try XCTUnwrap(dict["bool"] as? Bool)
        let date = try XCTUnwrap(dict["date"] as? Date)
        let decimal = try XCTUnwrap(dict["decimal"] as? Decimal)
        let double = try XCTUnwrap(dict["double"] as? Double)
        let float = try XCTUnwrap(dict["float"] as? Float)
        let int = try XCTUnwrap(dict["int"] as? Int)
        let string = try XCTUnwrap(dict["string"] as? String)
        let uuid = try XCTUnwrap(dict["uuid"] as? UUID)

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

    func testInsertSuccess() async throws {
        let fetchRequest = ManagedIdUrlModel_UuidId.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let request = try NSBatchInsertRequest(
            entityName: XCTUnwrap(ManagedModel_UuidId.entity().name),
            objects: values
        )
        let result: Result<NSBatchInsertResult, CoreDataError> = try await repository()
            .insert(request, transactionAuthor: transactionAuthor)

        switch result {
        case .success:
            XCTAssert(true)
        case .failure:
            XCTFail("Not expecting a failure result")
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["1", "2", "3", "4", "5"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testInsertFailure() async throws {
        let fetchRequest = ManagedIdUrlModel_UuidId.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let request = try NSBatchInsertRequest(
            entityName: XCTUnwrap(ManagedModel_UuidId.entity().name),
            objects: failureInsertMovies
        )
        let result: Result<NSBatchInsertResult, CoreDataError> = try await repository().insert(request)

        switch result {
        case .success:
            XCTFail("Not expecting a success result")
        case .failure:
            XCTAssert(true)
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(data.map(\.string).sorted(), [], "There should be no inserted values.")
        }
    }

    func testUpdateSuccess() async throws {
        let fetchRequest = ManagedIdUrlModel_UuidId.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let _ = try self.values
                .map(self.mapDictToManagedModel(_:))
            try self.repositoryContext().save()
        }

        let predicate = NSPredicate(value: true)
        let request = try NSBatchUpdateRequest(entityName: XCTUnwrap(ManagedModel_UuidId.entity().name))
        request.predicate = predicate
        request.propertiesToUpdate = ["string": "Updated!", "int": 1]

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let _: Result<NSBatchUpdateResult, CoreDataError> = try await repository()
            .update(request, transactionAuthor: transactionAuthor)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.string).sorted(),
                ["Updated!", "Updated!", "Updated!", "Updated!", "Updated!"],
                "Updated titles should match request"
            )
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDeleteSuccess() async throws {
        let fetchRequest = ManagedIdUrlModel_UuidId.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let _ = try self.values
                .map(self.mapDictToManagedModel(_:))
            try self.repositoryContext().save()
        }

        let request =
            try NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: XCTUnwrap(
                ManagedModel_UuidId
                    .entity().name
            )))

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let _: Result<NSBatchDeleteResult, CoreDataError> = try await repository()
            .delete(request, transactionAuthor: transactionAuthor)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(data.map(\.string).sorted(), [], "There should be no remaining values.")
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }
}
