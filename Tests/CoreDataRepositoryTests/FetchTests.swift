// FetchTests.swift
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
    struct FetchRepositoryTests: CoreDataTestSuite, @unchecked Sendable {
        let container: NSPersistentContainer
        let repositoryContext: NSManagedObjectContext
        let repository: CoreDataRepository

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

        mutating func extraSetup() async throws {
            let (_expectedValues, _objectIds) = try repositoryContext.performAndWait {
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

        @Test
        func fetchSuccess() async throws {
            switch await repository.fetch(fetchRequest, as: FetchableModel_UuidId.self) {
            case let .success(values):
                expectNoDifference(values.count, 5, "Result items count should match expectation")
                expectNoDifference(values, expectedValues, "Result items should match expectations")
            case .failure:
                Issue.record("Not expecting failure")
            }
        }

        @Test
        func fetchSubscriptionSuccess() async throws {
            let task = Task {
                var resultCount = 0
                let stream = repository
                    .fetchSubscription(fetchRequest, of: FetchableModel_UuidId.self)
                for await _items in stream {
                    let items = try _items.get()
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(items.count, 5, "Result items count should match expectation")
                        expectNoDifference(items, expectedValues, "Result items should match expectations")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(items.count, 4, "Result items count should match expectation")
                        expectNoDifference(
                            items,
                            Array(expectedValues[0 ... 3]),
                            "Result items should match expectations"
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

        @Test
        func fetchThrowingSubscriptionSuccess() async throws {
            let task = Task {
                var resultCount = 0
                let stream = repository.fetchThrowingSubscription(
                    fetchRequest,
                    of: FetchableModel_UuidId.self
                )
                for try await items in stream {
                    resultCount += 1
                    switch resultCount {
                    case 1:
                        expectNoDifference(items.count, 5, "Result items count should match expectation")
                        expectNoDifference(items, expectedValues, "Result items should match expectations")
                        try delete(managedId: #require(objectIds.last))
                        await Task.yield()
                    case 2:
                        expectNoDifference(items.count, 4, "Result items count should match expectation")
                        expectNoDifference(
                            items,
                            Array(expectedValues[0 ... 3]),
                            "Result items should match expectations"
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
