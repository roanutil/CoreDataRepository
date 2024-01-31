// FetchRepositoryTests.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import CoreDataRepository
import XCTest

final class FetchRepositoryTests: CoreDataXCTestCase {
    let fetchRequest: NSFetchRequest<ManagedMovie> = {
        let request = Movie.managedFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ManagedMovie.title, ascending: true)]
        return request
    }()

    let movies = [
        Movie(id: UUID(), title: "A", releaseDate: Date()),
        Movie(id: UUID(), title: "B", releaseDate: Date()),
        Movie(id: UUID(), title: "C", releaseDate: Date()),
        Movie(id: UUID(), title: "D", releaseDate: Date()),
        Movie(id: UUID(), title: "E", releaseDate: Date()),
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

    func testFetchSuccess() async throws {
        switch try await repository().fetch(fetchRequest, as: Movie.self) {
        case let .success(movies):
            XCTAssertEqual(movies.count, 5, "Result items count should match expectation")
            XCTAssertEqual(movies, expectedMovies, "Result items should match expectations")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testFetchSubscriptionSuccess() async throws {
        let task = Task {
            var resultCount = 0
            let stream = try repository()
                .fetchSubscription(fetchRequest, of: Movie.self)
            for await _items in stream {
                let items = try _items.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(items.count, 5, "Result items count should match expectation")
                    XCTAssertEqual(items, self.expectedMovies, "Result items should match expectations")
                    let crudRepository = try TestCoreDataRepository(context: repositoryContext())
                    let _: Result<Void, CoreDataError> = try await crudRepository
                        .delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(items.count, 4, "Result items count should match expectation")
                    XCTAssertEqual(items, Array(self.expectedMovies[0 ... 3]), "Result items should match expectations")
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
            let stream = try repository().fetchThrowingSubscription(self.fetchRequest, of: Movie.self)
            for try await items in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(items.count, 5, "Result items count should match expectation")
                    XCTAssertEqual(items, self.expectedMovies, "Result items should match expectations")
                    let crudRepository = try TestCoreDataRepository(context: self.repositoryContext())
                    let _: Result<Void, CoreDataError> = try await crudRepository
                        .delete(XCTUnwrap(expectedMovies.last?.url))
                    await Task.yield()
                case 2:
                    XCTAssertEqual(items.count, 4, "Result items count should match expectation")
                    XCTAssertEqual(items, Array(self.expectedMovies[0 ... 3]), "Result items should match expectations")
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
