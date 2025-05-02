// FetchTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import Internal
import XCTest

final class FetchRepositoryTests: CoreDataXCTestCase {
    let fetchRequest: NSFetchRequest<ManagedModel_UuidId> = {
        let request = FetchableModel_UuidId.managedFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true)]
        return request
    }()

    let values = [
        FetchableModel_UuidId.seeded(1),
        FetchableModel_UuidId.seeded(2),
        FetchableModel_UuidId.seeded(3),
        FetchableModel_UuidId.seeded(4),
        FetchableModel_UuidId.seeded(5),
    ]
    var expectedValues = [FetchableModel_UuidId]()
    var objectIds = [NSManagedObjectID]()

    override func setUpWithError() throws {
        try super.setUpWithError()
        let (_expectedValues, _objectIds) = try repositoryContext().performAndWait {
            let managedMovies = try self.values
                .map {
                    try ManagedIdUrlModel_UuidId(fetchable: $0)
                        .asManagedModel(in: repositoryContext())
                }
            try self.repositoryContext().save()
            return try (
                self.repositoryContext().fetch(fetchRequest).map(FetchableModel_UuidId.init(managed:)),
                managedMovies.map(\.objectID)
            )
        }
        expectedValues = _expectedValues
        objectIds = _objectIds
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        expectedValues = []
        objectIds = []
    }

    func testFetchSuccess() async throws {
        switch try await repository().fetch(fetchRequest, as: FetchableModel_UuidId.self) {
        case let .success(values):
            XCTAssertEqual(values.count, 5, "Result items count should match expectation")
            XCTAssertEqual(values, expectedValues, "Result items should match expectations")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testFetchSubscriptionSuccess() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository()
                .fetchSubscription(fetchRequest, of: FetchableModel_UuidId.self)
            for await _items in stream {
                let items = try _items.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(items.count, 5, "Result items count should match expectation")
                    XCTAssertEqual(items, self.expectedValues, "Result items should match expectations")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(items.count, 4, "Result items count should match expectation")
                    XCTAssertEqual(items, Array(self.expectedValues[0 ... 3]), "Result items should match expectations")
                    return resultCount
                default:
                    XCTFail("Not expecting any values past the first two.")
                    return resultCount
                }
            }
            return resultCount
        }
        let finalCount = try await task.value
        XCTAssertEqual(finalCount, 2)
    }

    func testFetchThrowingSubscriptionSuccess() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository().fetchThrowingSubscription(
                self.fetchRequest,
                of: FetchableModel_UuidId.self
            )
            for try await items in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(items.count, 5, "Result items count should match expectation")
                    XCTAssertEqual(items, self.expectedValues, "Result items should match expectations")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(items.count, 4, "Result items count should match expectation")
                    XCTAssertEqual(items, Array(self.expectedValues[0 ... 3]), "Result items should match expectations")
                    return resultCount
                default:
                    XCTFail("Not expecting any values past the first two.")
                    return resultCount
                }
            }
            return resultCount
        }
        let finalCount = try await task.value
        XCTAssertEqual(finalCount, 2)
    }
}
