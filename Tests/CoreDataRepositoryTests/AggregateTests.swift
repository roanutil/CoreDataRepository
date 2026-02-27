// AggregateTests.swift
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
    struct AggregateTests: CoreDataTestSuite, Sendable {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

        nonisolated(unsafe) let fetchRequest: NSFetchRequest<ManagedModel_UuidId> = {
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

        mutating func extraSetup() async throws {
            let (_expectedValues, _objectIds) = try repositoryContext.performAndWait { [
                self,
                repositoryContext,
                values
            ] in
                let managedMovies = try values
                    .map {
                        try ManagedIdUrlModel_UuidId(fetchable: $0)
                            .asManagedModel(in: repositoryContext)
                    }
                try repositoryContext.save()
                return try (
                    repositoryContext.fetch(fetchRequest).map(FetchableModel_UuidId.init(managed:)),
                    managedMovies.map(\.objectID)
                )
            }
            expectedValues = _expectedValues
            objectIds = _objectIds
        }

        @Test(arguments: [false, true])
        func countSuccess(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
                        .count(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            as: Int.self
                        )
                }
            } else {
                await repository
                    .count(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        as: Int.self
                    )
            }
            switch result {
            case let .success(value):
                expectNoDifference(value, 5, "Result value (count) should equal number of values.")
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func countSuccess_UnifiedEndpoint(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository.aggregate(
                        function: .count,
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Double.self
                    )
                }
            } else {
                try await repository.aggregate(
                    function: .count,
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    attributeDesc: #require(
                        ManagedModel_UuidId.entity().attributesByName.values
                            .first(where: { $0.name == "decimal" })
                    ),
                    as: Double.self
                )
            }
            switch result {
            case let .success(value):
                expectNoDifference(value, 5, "Result value (count) should equal number of values.")
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func countSubscription(inTransaction: Bool) async throws {
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        repository
                            .countSubscription(
                                predicate: NSPredicate(value: true),
                                entityDesc: ManagedModel_UuidId.entity(),
                                as: Int.self
                            )
                    }
                } else {
                    repository
                        .countSubscription(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            as: Int.self
                        )
                }
                for await _count in stream {
                    let count = try _count.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(count, 5, "Result value (count) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(count, 4, "Count should match expected value after deleting one value.")
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func countSubscriptionWithSplitFetchRequests(inTransaction: Bool) async throws {
            let changeTrackingRequest = try #require(UnmanagedModel_UuidId
                .managedFetchRequest() as? NSFetchRequest<NSManagedObject>)
            changeTrackingRequest.predicate = NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.int),
                rightExpression: NSExpression(forConstantValue: 30),
                modifier: .direct,
                type: .notEqualTo
            )
            changeTrackingRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true),
            ]
            let fetchPredicate = NSPredicate(value: true)
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        repository
                            .countSubscription(
                                predicate: fetchPredicate,
                                changeTrackingRequest: changeTrackingRequest,
                                entityDesc: ManagedModel_UuidId.entity(),
                                as: Int.self
                            )
                    }
                } else {
                    repository
                        .countSubscription(
                            predicate: fetchPredicate,
                            changeTrackingRequest: changeTrackingRequest,
                            entityDesc: ManagedModel_UuidId.entity(),
                            as: Int.self
                        )
                }
                for await _count in stream {
                    let count = try _count.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(count, 5, "Result value (count) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(count, 4, "Count should match expected value after deleting one value.")
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func countThrowingSubscription(inTransaction: Bool) async throws {
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        repository
                            .countThrowingSubscription(
                                predicate: NSPredicate(value: true),
                                entityDesc: ManagedModel_UuidId.entity(),
                                as: Int.self
                            )
                    }
                } else {
                    repository
                        .countThrowingSubscription(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            as: Int.self
                        )
                }
                for try await count in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(count, 5, "Result value (count) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(count, 4, "Count should match expected value after deleting one value.")
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func countThrowingSubscriptionWithSplitFetchRequests(inTransaction: Bool) async throws {
            let changeTrackingRequest = try #require(UnmanagedModel_UuidId
                .managedFetchRequest() as? NSFetchRequest<NSManagedObject>)
            changeTrackingRequest.predicate = NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.int),
                rightExpression: NSExpression(forConstantValue: 30),
                modifier: .direct,
                type: .notEqualTo
            )
            changeTrackingRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true),
            ]
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        repository
                            .countThrowingSubscription(
                                predicate: NSPredicate(value: true),
                                changeTrackingRequest: changeTrackingRequest,
                                entityDesc: ManagedModel_UuidId.entity(),
                                as: Int.self
                            )
                    }
                } else {
                    repository
                        .countThrowingSubscription(
                            predicate: NSPredicate(value: true),
                            changeTrackingRequest: changeTrackingRequest,
                            entityDesc: ManagedModel_UuidId.entity(),
                            as: Int.self
                        )
                }
                for try await count in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(count, 5, "Result value (count) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(count, 4, "Count should match expected value after deleting one value.")
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func sumSuccess(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository.sum(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
            } else {
                try await repository.sum(
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    attributeDesc: #require(
                        ManagedModel_UuidId.entity().attributesByName.values
                            .first(where: { $0.name == "decimal" })
                    ),
                    as: Decimal.self
                )
            }
            switch result {
            case let .success(value):
                expectNoDifference(value, 150, "Result value (sum) should equal number of values.")
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func sumSuccess_UnifiedEndpoint(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository.aggregate(
                        function: .sum,
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
            } else {
                try await repository.aggregate(
                    function: .sum,
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    attributeDesc: #require(
                        ManagedModel_UuidId.entity().attributesByName.values
                            .first(where: { $0.name == "decimal" })
                    ),
                    as: Decimal.self
                )
            }
            switch result {
            case let .success(value):
                expectNoDifference(value, 150, "Result value (sum) should equal number of values.")
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func sumSubscription(inTransaction: Bool) async throws {
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.sumSubscription(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.sumSubscription(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for await _sum in stream {
                    let sum = try _sum.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(sum, 150, "Result value (sum) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            sum,
                            100,
                            "Result value (sum) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func sumSubscriptionWithSplitFetchRequests(inTransaction: Bool) async throws {
            let changeTrackingRequest = try #require(UnmanagedModel_UuidId
                .managedFetchRequest() as? NSFetchRequest<NSManagedObject>)
            changeTrackingRequest.predicate = NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.int),
                rightExpression: NSExpression(forConstantValue: 30),
                modifier: .direct,
                type: .notEqualTo
            )
            changeTrackingRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true),
            ]
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.sumSubscription(
                            predicate: NSPredicate(value: true),
                            changeTrackingRequest: changeTrackingRequest,
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.sumSubscription(
                        predicate: NSPredicate(value: true),
                        changeTrackingRequest: changeTrackingRequest,
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for await _sum in stream {
                    let sum = try _sum.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(sum, 150, "Result value (sum) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            sum,
                            100,
                            "Result value (sum) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func sumThrowingSubscription(inTransaction: Bool) async throws {
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.sumThrowingSubscription(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.sumThrowingSubscription(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for try await sum in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(sum, 150, "Result value (sum) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            sum,
                            100,
                            "Result value (sum) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func sumThrowingSubscriptionWithSplitFetchRequests(inTransaction: Bool) async throws {
            let changeTrackingRequest = try #require(UnmanagedModel_UuidId
                .managedFetchRequest() as? NSFetchRequest<NSManagedObject>)
            changeTrackingRequest.predicate = NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.int),
                rightExpression: NSExpression(forConstantValue: 30),
                modifier: .direct,
                type: .notEqualTo
            )
            changeTrackingRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true),
            ]
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.sumThrowingSubscription(
                            predicate: NSPredicate(value: true),
                            changeTrackingRequest: changeTrackingRequest,
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.sumThrowingSubscription(
                        predicate: NSPredicate(value: true),
                        changeTrackingRequest: changeTrackingRequest,
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for try await sum in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(sum, 150, "Result value (sum) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            sum,
                            100,
                            "Result value (sum) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func averageSuccess(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository.average(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
            } else {
                try await repository.average(
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    attributeDesc: #require(
                        ManagedModel_UuidId.entity().attributesByName.values
                            .first(where: { $0.name == "decimal" })
                    ),
                    as: Decimal.self
                )
            }
            switch result {
            case let .success(value):
                expectNoDifference(
                    value,
                    30,
                    "Result value should equal average of values box office."
                )
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func averageSuccess_UnifiedEndpoint(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository.aggregate(
                        function: .average,
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
            } else {
                try await repository.aggregate(
                    function: .average,
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    attributeDesc: #require(
                        ManagedModel_UuidId.entity().attributesByName.values
                            .first(where: { $0.name == "decimal" })
                    ),
                    as: Decimal.self
                )
            }
            switch result {
            case let .success(value):
                expectNoDifference(
                    value,
                    30,
                    "Result value should equal average of values box office."
                )
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func averageSubscription(inTransaction: Bool) async throws {
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.averageSubscription(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.averageSubscription(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for await _average in stream {
                    let average = try _average.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(average, 30, "Result value (average) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            average,
                            25,
                            "Result value (average) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func averageSubscriptionWithSplitFetchRequests(inTransaction: Bool) async throws {
            let changeTrackingRequest = try #require(UnmanagedModel_UuidId
                .managedFetchRequest() as? NSFetchRequest<NSManagedObject>)
            changeTrackingRequest.predicate = NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.int),
                rightExpression: NSExpression(forConstantValue: 30),
                modifier: .direct,
                type: .notEqualTo
            )
            changeTrackingRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true),
            ]
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.averageSubscription(
                            predicate: NSPredicate(value: true),
                            changeTrackingRequest: changeTrackingRequest,
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.averageSubscription(
                        predicate: NSPredicate(value: true),
                        changeTrackingRequest: changeTrackingRequest,
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for await _average in stream {
                    let average = try _average.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(average, 30, "Result value (average) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            average,
                            25,
                            "Result value (average) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func averageThrowingSubscription(inTransaction: Bool) async throws {
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.averageThrowingSubscription(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.averageThrowingSubscription(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for try await average in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(average, 30, "Result value (average) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            average,
                            25,
                            "Result value (average) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func averageThrowingSubscriptionWithSplitFetchRequests(inTransaction: Bool) async throws {
            let changeTrackingRequest = try #require(UnmanagedModel_UuidId
                .managedFetchRequest() as? NSFetchRequest<NSManagedObject>)
            changeTrackingRequest.predicate = NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.int),
                rightExpression: NSExpression(forConstantValue: 30),
                modifier: .direct,
                type: .notEqualTo
            )
            changeTrackingRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true),
            ]
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.averageThrowingSubscription(
                            predicate: NSPredicate(value: true),
                            changeTrackingRequest: changeTrackingRequest,
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.averageThrowingSubscription(
                        predicate: NSPredicate(value: true),
                        changeTrackingRequest: changeTrackingRequest,
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for try await average in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(average, 30, "Result value (average) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            average,
                            25,
                            "Result value (average) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func minSuccess(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository.min(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
            } else {
                try await repository.min(
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    attributeDesc: #require(
                        ManagedModel_UuidId.entity().attributesByName.values
                            .first(where: { $0.name == "decimal" })
                    ),
                    as: Decimal.self
                )
            }
            switch result {
            case let .success(value):
                expectNoDifference(
                    value,
                    10,
                    "Result value should equal min of values box office."
                )
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func minSuccess_UnifiedEndpoint(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository.aggregate(
                        function: .min,
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
            } else {
                try await repository.aggregate(
                    function: .min,
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    attributeDesc: #require(
                        ManagedModel_UuidId.entity().attributesByName.values
                            .first(where: { $0.name == "decimal" })
                    ),
                    as: Decimal.self
                )
            }
            switch result {
            case let .success(value):
                expectNoDifference(
                    value,
                    10,
                    "Result value should equal min of values box office."
                )
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func minSubscription(inTransaction: Bool) async throws {
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.minSubscription(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.minSubscription(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for await _min in stream {
                    let min = try _min.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(min, 10, "Result value (min) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            min,
                            10,
                            "Result value (min) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func minSubscriptionWithSplitFetchRequests(inTransaction: Bool) async throws {
            let changeTrackingRequest = try #require(UnmanagedModel_UuidId
                .managedFetchRequest() as? NSFetchRequest<NSManagedObject>)
            changeTrackingRequest.predicate = NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.int),
                rightExpression: NSExpression(forConstantValue: 30),
                modifier: .direct,
                type: .notEqualTo
            )
            changeTrackingRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true),
            ]
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.minSubscription(
                            predicate: NSPredicate(value: true),
                            changeTrackingRequest: changeTrackingRequest,
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.minSubscription(
                        predicate: NSPredicate(value: true),
                        changeTrackingRequest: changeTrackingRequest,
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for await _min in stream {
                    let min = try _min.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(min, 10, "Result value (min) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            min,
                            10,
                            "Result value (min) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func minThrowingSubscription(inTransaction: Bool) async throws {
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.minThrowingSubscription(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.minThrowingSubscription(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for try await min in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(min, 10, "Result value (min) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            min,
                            10,
                            "Result value (min) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func minThrowingSubscriptionWithSplitFetchRequests(inTransaction: Bool) async throws {
            let changeTrackingRequest = try #require(UnmanagedModel_UuidId
                .managedFetchRequest() as? NSFetchRequest<NSManagedObject>)
            changeTrackingRequest.predicate = NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.int),
                rightExpression: NSExpression(forConstantValue: 30),
                modifier: .direct,
                type: .notEqualTo
            )
            changeTrackingRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true),
            ]
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.minThrowingSubscription(
                            predicate: NSPredicate(value: true),
                            changeTrackingRequest: changeTrackingRequest,
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.minThrowingSubscription(
                        predicate: NSPredicate(value: true),
                        changeTrackingRequest: changeTrackingRequest,
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for try await min in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(min, 10, "Result value (min) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            min,
                            10,
                            "Result value (min) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func maxSuccess(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository.max(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
            } else {
                try await repository.max(
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    attributeDesc: #require(
                        ManagedModel_UuidId.entity().attributesByName.values
                            .first(where: { $0.name == "decimal" })
                    ),
                    as: Decimal.self
                )
            }
            switch result {
            case let .success(value):
                expectNoDifference(
                    value,
                    50,
                    "Result value should equal max of values box office."
                )
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func maxSuccess_UnifiedEndpoint(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository.aggregate(
                        function: .max,
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
            } else {
                try await repository.aggregate(
                    function: .max,
                    predicate: NSPredicate(value: true),
                    entityDesc: ManagedModel_UuidId.entity(),
                    attributeDesc: #require(
                        ManagedModel_UuidId.entity().attributesByName.values
                            .first(where: { $0.name == "decimal" })
                    ),
                    as: Decimal.self
                )
            }
            switch result {
            case let .success(value):
                expectNoDifference(
                    value,
                    50,
                    "Result value should equal max of values box office."
                )
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func maxSubscription(inTransaction: Bool) async throws {
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.maxSubscription(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.maxSubscription(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for await _max in stream {
                    let max = try _max.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(max, 50, "Result value (max) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            max,
                            40,
                            "Result value (max) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func maxSubscriptionWithSplitFetchRequests(inTransaction: Bool) async throws {
            let changeTrackingRequest = try #require(UnmanagedModel_UuidId
                .managedFetchRequest() as? NSFetchRequest<NSManagedObject>)
            changeTrackingRequest.predicate = NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.int),
                rightExpression: NSExpression(forConstantValue: 30),
                modifier: .direct,
                type: .notEqualTo
            )
            changeTrackingRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true),
            ]
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.maxSubscription(
                            predicate: NSPredicate(value: true),
                            changeTrackingRequest: changeTrackingRequest,
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.maxSubscription(
                        predicate: NSPredicate(value: true),
                        changeTrackingRequest: changeTrackingRequest,
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for await _max in stream {
                    let max = try _max.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(max, 50, "Result value (max) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            max,
                            40,
                            "Result value (max) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func maxThrowingSubscription(inTransaction: Bool) async throws {
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.maxThrowingSubscription(
                            predicate: NSPredicate(value: true),
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.maxThrowingSubscription(
                        predicate: NSPredicate(value: true),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for try await max in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(max, 50, "Result value (max) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            max,
                            40,
                            "Result value (max) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func maxThrowingSubscriptionWithSplitFetchRequests(inTransaction: Bool) async throws {
            let changeTrackingRequest = try #require(UnmanagedModel_UuidId
                .managedFetchRequest() as? NSFetchRequest<NSManagedObject>)
            changeTrackingRequest.predicate = NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.int),
                rightExpression: NSExpression(forConstantValue: 30),
                modifier: .direct,
                type: .notEqualTo
            )
            changeTrackingRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ManagedModel_UuidId.int, ascending: true),
            ]
            let task = Task {
                var resultCount = 0
                let stream = if inTransaction {
                    try await repository.withTransaction { _ in
                        try repository.maxThrowingSubscription(
                            predicate: NSPredicate(value: true),
                            changeTrackingRequest: changeTrackingRequest,
                            entityDesc: ManagedModel_UuidId.entity(),
                            attributeDesc: #require(
                                ManagedModel_UuidId.entity().attributesByName.values
                                    .first(where: { $0.name == "decimal" })
                            ),
                            as: Decimal.self
                        )
                    }
                } else {
                    try repository.maxThrowingSubscription(
                        predicate: NSPredicate(value: true),
                        changeTrackingRequest: changeTrackingRequest,
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
                for try await max in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(max, 50, "Result value (max) should equal number of values.")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(
                            max,
                            40,
                            "Result value (max) should match expected value after deleting one value."
                        )
                        return resultCount
                    default:
                        Issue.record("Not expecting any values past the first two.")
                        return resultCount
                    }
                }
                return resultCount
            }
            let finalCount = try await task.value
            expectNoDifference(finalCount, 2)
        }

        @Test(arguments: [false, true])
        func countWithPredicate(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    await repository
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
                }
            } else {
                await repository
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
            }
            switch result {
            case let .success(count):
                expectNoDifference(count, 4, "Result value (count) should equal number of values not titled 'A'.")
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test(arguments: [false, true])
        func sumWithPredicate(inTransaction: Bool) async throws {
            let result = if inTransaction {
                try await repository.withTransaction { _ in
                    try await repository.sum(
                        predicate: NSComparisonPredicate(
                            leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.string),
                            rightExpression: NSExpression(forConstantValue: "10"),
                            modifier: .direct,
                            type: .notEqualTo
                        ),
                        entityDesc: ManagedModel_UuidId.entity(),
                        attributeDesc: #require(
                            ManagedModel_UuidId.entity().attributesByName.values
                                .first(where: { $0.name == "decimal" })
                        ),
                        as: Decimal.self
                    )
                }
            } else {
                try await repository.sum(
                    predicate: NSComparisonPredicate(
                        leftExpression: NSExpression(forKeyPath: \ManagedModel_UuidId.string),
                        rightExpression: NSExpression(forConstantValue: "10"),
                        modifier: .direct,
                        type: .notEqualTo
                    ),
                    entityDesc: ManagedModel_UuidId.entity(),
                    attributeDesc: #require(
                        ManagedModel_UuidId.entity().attributesByName.values
                            .first(where: { $0.name == "decimal" })
                    ),
                    as: Decimal.self
                )
            }
            switch result {
            case let .success(sum):
                expectNoDifference(
                    sum,
                    140,
                    "Result value should equal sum of values box office that are not titled 'A'."
                )
            case .failure:
                Issue.record("Not expecting failure")
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
