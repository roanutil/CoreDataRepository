// AggregateRepositoryTests.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import CoreDataRepository
import XCTest

final class AggregateRepositoryTests: CoreDataXCTestCase {
    let fetchRequest: NSFetchRequest<RepoMovie> = {
        let request = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RepoMovie.title, ascending: true)]
        return request
    }()

    let movies = [
        Movie(id: UUID(), title: "A", releaseDate: Date(), boxOffice: 10),
        Movie(id: UUID(), title: "B", releaseDate: Date(), boxOffice: 20),
        Movie(id: UUID(), title: "C", releaseDate: Date(), boxOffice: 30),
        Movie(id: UUID(), title: "D", releaseDate: Date(), boxOffice: 40),
        Movie(id: UUID(), title: "E", releaseDate: Date(), boxOffice: 50),
    ]
    var expectedMovies = [Movie]()

    override func setUpWithError() throws {
        try super.setUpWithError()
        expectedMovies = try repositoryContext().performAndWait {
            _ = try self.movies.map { try $0.asManagedModel(in: repositoryContext()) }
            try self.repositoryContext().save()
            return try self.repositoryContext().fetch(fetchRequest).map(Movie.init(managed:))
        }
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        expectedMovies = []
    }

    func testCountSuccess() async throws {
        let result = try await repository()
            .count(predicate: NSPredicate(value: true), entityDesc: RepoMovie.entity(), as: Int.self)
        switch result {
        case let .success(value):
            XCTAssertEqual(value, 5, "Result value (count) should equal number of movies.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testCountSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository()
                .countSubscription(predicate: NSPredicate(value: true), entityDesc: RepoMovie.entity(), as: Int.self)
            for await _count in stream {
                let count = try _count.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(count, 5, "Result value (count) should equal number of movies.")
                    let crudRepository = try CoreDataRepository(context: repositoryContext())
                    _ = try await crudRepository.delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(count, 4, "Count should match expected value after deleting one movie.")
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
                    entityDesc: RepoMovie.entity(),
                    as: Int.self
                )
            for try await count in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(count, 5, "Result value (count) should equal number of movies.")
                    let crudRepository = try CoreDataRepository(context: repositoryContext())
                    _ = try await crudRepository.delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(count, 4, "Count should match expected value after deleting one movie.")
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
            entityDesc: RepoMovie.entity(),
            attributeDesc: XCTUnwrap(
                RepoMovie.entity().attributesByName.values
                    .first(where: { $0.name == "boxOffice" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(value, 150, "Result value (sum) should equal number of movies.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testSumSubscription() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository().sumSubscription(
                predicate: NSPredicate(value: true),
                entityDesc: RepoMovie.entity(),
                attributeDesc: XCTUnwrap(
                    RepoMovie.entity().attributesByName.values
                        .first(where: { $0.name == "boxOffice" })
                ),
                as: Decimal.self
            )
            for await _sum in stream {
                let sum = try _sum.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(sum, 150, "Result value (sum) should equal number of movies.")
                    let crudRepository = try CoreDataRepository(context: repositoryContext())
                    _ = try await crudRepository.delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(sum, 100, "Result value (sum) should match expected value after deleting one movie.")
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
                entityDesc: RepoMovie.entity(),
                attributeDesc: XCTUnwrap(
                    RepoMovie.entity().attributesByName.values
                        .first(where: { $0.name == "boxOffice" })
                ),
                as: Decimal.self
            )
            for try await sum in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(sum, 150, "Result value (sum) should equal number of movies.")
                    let crudRepository = try CoreDataRepository(context: repositoryContext())
                    _ = try await crudRepository.delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(sum, 100, "Result value (sum) should match expected value after deleting one movie.")
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
            entityDesc: RepoMovie.entity(),
            attributeDesc: XCTUnwrap(
                RepoMovie.entity().attributesByName.values
                    .first(where: { $0.name == "boxOffice" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(
                value,
                30,
                "Result value should equal average of movies box office."
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
                entityDesc: RepoMovie.entity(),
                attributeDesc: XCTUnwrap(
                    RepoMovie.entity().attributesByName.values
                        .first(where: { $0.name == "boxOffice" })
                ),
                as: Decimal.self
            )
            for await _average in stream {
                let average = try _average.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(average, 30, "Result value (average) should equal number of movies.")
                    let crudRepository = try CoreDataRepository(context: repositoryContext())
                    _ = try await crudRepository.delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(
                        average,
                        25,
                        "Result value (average) should match expected value after deleting one movie."
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
                entityDesc: RepoMovie.entity(),
                attributeDesc: XCTUnwrap(
                    RepoMovie.entity().attributesByName.values
                        .first(where: { $0.name == "boxOffice" })
                ),
                as: Decimal.self
            )
            for try await average in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(average, 30, "Result value (average) should equal number of movies.")
                    let crudRepository = try CoreDataRepository(context: repositoryContext())
                    _ = try await crudRepository.delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(
                        average,
                        25,
                        "Result value (average) should match expected value after deleting one movie."
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
            entityDesc: RepoMovie.entity(),
            attributeDesc: XCTUnwrap(
                RepoMovie.entity().attributesByName.values
                    .first(where: { $0.name == "boxOffice" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(
                value,
                10,
                "Result value should equal min of movies box office."
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
                entityDesc: RepoMovie.entity(),
                attributeDesc: XCTUnwrap(
                    RepoMovie.entity().attributesByName.values
                        .first(where: { $0.name == "boxOffice" })
                ),
                as: Decimal.self
            )
            for await _min in stream {
                let min = try _min.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(min, 10, "Result value (min) should equal number of movies.")
                    let crudRepository = try CoreDataRepository(context: repositoryContext())
                    _ = try await crudRepository.delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(min, 10, "Result value (min) should match expected value after deleting one movie.")
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
                entityDesc: RepoMovie.entity(),
                attributeDesc: XCTUnwrap(
                    RepoMovie.entity().attributesByName.values
                        .first(where: { $0.name == "boxOffice" })
                ),
                as: Decimal.self
            )
            for try await min in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(min, 10, "Result value (min) should equal number of movies.")
                    let crudRepository = try CoreDataRepository(context: repositoryContext())
                    _ = try await crudRepository.delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(min, 10, "Result value (min) should match expected value after deleting one movie.")
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
            entityDesc: RepoMovie.entity(),
            attributeDesc: XCTUnwrap(
                RepoMovie.entity().attributesByName.values
                    .first(where: { $0.name == "boxOffice" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(value):
            XCTAssertEqual(
                value,
                50,
                "Result value should equal max of movies box office."
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
                entityDesc: RepoMovie.entity(),
                attributeDesc: XCTUnwrap(
                    RepoMovie.entity().attributesByName.values
                        .first(where: { $0.name == "boxOffice" })
                ),
                as: Decimal.self
            )
            for await _max in stream {
                let max = try _max.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(max, 50, "Result value (max) should equal number of movies.")
                    let crudRepository = try CoreDataRepository(context: repositoryContext())
                    _ = try await crudRepository.delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(max, 40, "Result value (max) should match expected value after deleting one movie.")
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
                entityDesc: RepoMovie.entity(),
                attributeDesc: XCTUnwrap(
                    RepoMovie.entity().attributesByName.values
                        .first(where: { $0.name == "boxOffice" })
                ),
                as: Decimal.self
            )
            for try await max in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(max, 50, "Result value (max) should equal number of movies.")
                    let crudRepository = try CoreDataRepository(context: repositoryContext())
                    _ = try await crudRepository.delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(max, 40, "Result value (max) should match expected value after deleting one movie.")
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
                    leftExpression: NSExpression(forKeyPath: \RepoMovie.title),
                    rightExpression: NSExpression(forConstantValue: "A"),
                    modifier: .direct,
                    type: .notEqualTo
                ),
                entityDesc: RepoMovie.entity(),
                as: Int.self
            )
        switch result {
        case let .success(count):
            XCTAssertEqual(count, 4, "Result value (count) should equal number of movies not titled 'A'.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testSumWithPredicate() async throws {
        let result = try await repository().sum(
            predicate: NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \RepoMovie.title),
                rightExpression: NSExpression(forConstantValue: "A"),
                modifier: .direct,
                type: .notEqualTo
            ),
            entityDesc: RepoMovie.entity(),
            attributeDesc: XCTUnwrap(
                RepoMovie.entity().attributesByName.values
                    .first(where: { $0.name == "boxOffice" })
            ),
            as: Decimal.self
        )
        switch result {
        case let .success(sum):
            XCTAssertEqual(
                sum,
                140,
                "Result value should equal sum of movies box office that are not titled 'A'."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }
}
