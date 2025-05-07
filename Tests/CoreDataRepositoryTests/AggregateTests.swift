// AggregateTests.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import Internal
import XCTest

final class CoreDataRepository_AggregateTests: CoreDataXCTestCase {
    let fetchRequest: NSFetchRequest<ManagedModel_UuidId> = {
        let request = UnmanagedModel_UuidId.managedFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true)]
        return request
    }()

    let values = [
        FetchableModel_UuidId.seeded(10),
        FetchableModel_UuidId.seeded(20),
        FetchableModel_UuidId.seeded(30),
        FetchableModel_UuidId.seeded(40),
        FetchableModel_UuidId.seeded(50),
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

    func testCountSuccess() async throws {
        let result = try await repository()
            .count(
                predicate: NSPredicate(value: true),
                entityDesc: ManagedModel_UuidId.entity(),
                as: Int.self
            )
        switch result {
        case let .success(value):
            XCTAssertEqual(value, 5, "Result value (count) should equal number of values.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testCountSuccess_UnifiedEndpoint() async throws {
        let result = try await repository().aggregate(
            function: .count,
            predicate: NSPredicate(value: true),
            entityDesc: ManagedModel_UuidId.entity(),
            attributeDesc: XCTUnwrap(
                ManagedModel_UuidId.entity().attributesByName.values
                    .first(where: { $0.name == "decimal" })
            ),
            as: Double.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(value, 5, "Result value (count) should equal number of values.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testCountSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository()
                .countSubscription(
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    as: Int.self
                )
            for await _count in stream {
                let count = try _count.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(count, 5, "Result value (count) should equal number of values.")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(count, 4, "Count should match expected value after deleting one value.")
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

    func testCountThrowingSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository()
                .countThrowingSubscription(
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    as: Int.self
                )
            for try await count in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(count, 5, "Result value (count) should equal number of values.")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(count, 4, "Count should match expected value after deleting one value.")
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

    func testSumSuccess() async throws {
        let result = try await repository().sum(
            predicate: NSPredicate(value: true),
            entityDesc: ManagedModel_UuidId.entity(),
            attributeDesc: XCTUnwrap(
                ManagedModel_UuidId.entity().attributesByName.values
                    .first(where: { $0.name == "decimal" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(value, 150, "Result value (sum) should equal number of values.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testSumSuccess_UnifiedEndpoint() async throws {
        let result = try await repository().aggregate(
            function: .sum,
            predicate: NSPredicate(value: true),
            entityDesc: ManagedModel_UuidId.entity(),
            attributeDesc: XCTUnwrap(
                ManagedModel_UuidId.entity().attributesByName.values
                    .first(where: { $0.name == "decimal" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(value, 150, "Result value (sum) should equal number of values.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testSumSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository().sumSubscription(
                predicate: NSPredicate(value: true),
                entityDesc: ManagedModel_UuidId.entity(),
                attributeDesc: XCTUnwrap(
                    ManagedModel_UuidId.entity().attributesByName.values
                        .first(where: { $0.name == "decimal" })
                ),
                as: Decimal.self
            )
            for await _sum in stream {
                let sum = try _sum.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(sum, 150, "Result value (sum) should equal number of values.")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(sum, 100, "Result value (sum) should match expected value after deleting one value.")
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

    func testSumThrowingSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository().sumThrowingSubscription(
                predicate: NSPredicate(value: true),
                entityDesc: ManagedModel_UuidId.entity(),
                attributeDesc: XCTUnwrap(
                    ManagedModel_UuidId.entity().attributesByName.values
                        .first(where: { $0.name == "decimal" })
                ),
                as: Decimal.self
            )
            for try await sum in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(sum, 150, "Result value (sum) should equal number of values.")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(sum, 100, "Result value (sum) should match expected value after deleting one value.")
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

    func testAverageSuccess() async throws {
        let result = try await repository().average(
            predicate: NSPredicate(value: true),
            entityDesc: ManagedModel_UuidId.entity(),
            attributeDesc: XCTUnwrap(
                ManagedModel_UuidId.entity().attributesByName.values
                    .first(where: { $0.name == "decimal" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(
                value,
                30,
                "Result value should equal average of values box office."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testAverageSuccess_UnifiedEndpoint() async throws {
        let result = try await repository().aggregate(
            function: .average,
            predicate: NSPredicate(value: true),
            entityDesc: ManagedModel_UuidId.entity(),
            attributeDesc: XCTUnwrap(
                ManagedModel_UuidId.entity().attributesByName.values
                    .first(where: { $0.name == "decimal" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(
                value,
                30,
                "Result value should equal average of values box office."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testAverageSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository().averageSubscription(
                predicate: NSPredicate(value: true),
                entityDesc: ManagedModel_UuidId.entity(),
                attributeDesc: XCTUnwrap(
                    ManagedModel_UuidId.entity().attributesByName.values
                        .first(where: { $0.name == "decimal" })
                ),
                as: Decimal.self
            )
            for await _average in stream {
                let average = try _average.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(average, 30, "Result value (average) should equal number of values.")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(
                        average,
                        25,
                        "Result value (average) should match expected value after deleting one value."
                    )
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

    func testAverageThrowingSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository().averageThrowingSubscription(
                predicate: NSPredicate(value: true),
                entityDesc: ManagedModel_UuidId.entity(),
                attributeDesc: XCTUnwrap(
                    ManagedModel_UuidId.entity().attributesByName.values
                        .first(where: { $0.name == "decimal" })
                ),
                as: Decimal.self
            )
            for try await average in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(average, 30, "Result value (average) should equal number of values.")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(
                        average,
                        25,
                        "Result value (average) should match expected value after deleting one value."
                    )
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

    func testMinSuccess() async throws {
        let result = try await repository().min(
            predicate: NSPredicate(value: true),
            entityDesc: ManagedModel_UuidId.entity(),
            attributeDesc: XCTUnwrap(
                ManagedModel_UuidId.entity().attributesByName.values
                    .first(where: { $0.name == "decimal" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(
                value,
                10,
                "Result value should equal min of values box office."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testMinSuccess_UnifiedEndpoint() async throws {
        let result = try await repository().aggregate(
            function: .min,
            predicate: NSPredicate(value: true),
            entityDesc: ManagedModel_UuidId.entity(),
            attributeDesc: XCTUnwrap(
                ManagedModel_UuidId.entity().attributesByName.values
                    .first(where: { $0.name == "decimal" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(
                value,
                10,
                "Result value should equal min of values box office."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testMinSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository().minSubscription(
                predicate: NSPredicate(value: true),
                entityDesc: ManagedModel_UuidId.entity(),
                attributeDesc: XCTUnwrap(
                    ManagedModel_UuidId.entity().attributesByName.values
                        .first(where: { $0.name == "decimal" })
                ),
                as: Decimal.self
            )
            for await _min in stream {
                let min = try _min.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(min, 10, "Result value (min) should equal number of values.")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(min, 10, "Result value (min) should match expected value after deleting one value.")
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

    func testMinThrowingSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository().minThrowingSubscription(
                predicate: NSPredicate(value: true),
                entityDesc: ManagedModel_UuidId.entity(),
                attributeDesc: XCTUnwrap(
                    ManagedModel_UuidId.entity().attributesByName.values
                        .first(where: { $0.name == "decimal" })
                ),
                as: Decimal.self
            )
            for try await min in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(min, 10, "Result value (min) should equal number of values.")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(min, 10, "Result value (min) should match expected value after deleting one value.")
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

    func testMaxSuccess() async throws {
        let result = try await repository().max(
            predicate: NSPredicate(value: true),
            entityDesc: ManagedModel_UuidId.entity(),
            attributeDesc: XCTUnwrap(
                ManagedModel_UuidId.entity().attributesByName.values
                    .first(where: { $0.name == "decimal" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(
                value,
                50,
                "Result value should equal max of values box office."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testMaxSuccess_UnifiedEndpoint() async throws {
        let result = try await repository().aggregate(
            function: .max,
            predicate: NSPredicate(value: true),
            entityDesc: ManagedModel_UuidId.entity(),
            attributeDesc: XCTUnwrap(
                ManagedModel_UuidId.entity().attributesByName.values
                    .first(where: { $0.name == "decimal" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(
                value,
                50,
                "Result value should equal max of values box office."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testMaxSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository().maxSubscription(
                predicate: NSPredicate(value: true),
                entityDesc: ManagedModel_UuidId.entity(),
                attributeDesc: XCTUnwrap(
                    ManagedModel_UuidId.entity().attributesByName.values
                        .first(where: { $0.name == "decimal" })
                ),
                as: Decimal.self
            )
            for await _max in stream {
                let max = try _max.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(max, 50, "Result value (max) should equal number of values.")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(max, 40, "Result value (max) should match expected value after deleting one value.")
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

    func testMaxThrowingSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository().maxThrowingSubscription(
                predicate: NSPredicate(value: true),
                entityDesc: ManagedModel_UuidId.entity(),
                attributeDesc: XCTUnwrap(
                    ManagedModel_UuidId.entity().attributesByName.values
                        .first(where: { $0.name == "decimal" })
                ),
                as: Decimal.self
            )
            for try await max in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(max, 50, "Result value (max) should equal number of values.")
                    try delete(managedId: XCTUnwrap(objectIds.last))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(max, 40, "Result value (max) should match expected value after deleting one value.")
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

    func testCountWithPredicate() async throws {
        let result = try await repository()
            .count(
                predicate: NSComparisonPredicate(
                    leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.string),
                    rightExpression: NSExpression(forConstantValue: "10"),
                    modifier: .direct,
                    type: .notEqualTo
                ),
                entityDesc: ManagedModel_UuidId.entity(),
                as: Int.self
            )
        switch result {
        case let .success(count):
            XCTAssertEqual(count, 4, "Result value (count) should equal number of values not titled 'A'.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testSumWithPredicate() async throws {
        let result = try await repository().sum(
            predicate: NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.string),
                rightExpression: NSExpression(forConstantValue: "10"),
                modifier: .direct,
                type: .notEqualTo
            ),
            entityDesc: ManagedModel_UuidId.entity(),
            attributeDesc: XCTUnwrap(
                ManagedModel_UuidId.entity().attributesByName.values
                    .first(where: { $0.name == "decimal" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(sum):
            XCTAssertEqual(
                sum,
                140,
                "Result value should equal sum of values box office that are not titled 'A'."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }
}
