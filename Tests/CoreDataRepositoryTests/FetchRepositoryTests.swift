// FetchRepositoryTests.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import Combine
import CoreData
import CoreDataRepository
import XCTest

final class FetchRepositoryTests: CoreDataXCTestCase {
    static var allTests = [
        ("testFetchSuccess", testFetchSuccess),
        ("testFetchSubscriptionSuccess", testFetchSubscriptionSuccess),
    ]

    let fetchRequest: NSFetchRequest<RepoMovie> = {
        let request = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RepoMovie.title, ascending: true)]
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
        try repositoryContext().performAndWait {
            do {
                _ = try movies.map { $0.asRepoManaged(in: try repositoryContext()) }
                try repositoryContext().save()
                expectedMovies = try repositoryContext().fetch(fetchRequest).map(\.asUnmanaged)
            } catch {
                XCTFail("Failed to setup context")
            }
            
        }
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        expectedMovies = []
    }

    func testFetchSuccess() throws {
        let exp = expectation(description: "Fetch movies from CoreData")
        let result: AnyPublisher<[Movie], CoreDataRepositoryError> = try repository().fetch(fetchRequest)
        result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    exp.fulfill()
                default:
                    XCTFail("Not expecting failure")
                }
            }, receiveValue: { items in
                XCTAssert(items.count == 5, "Result items count should match expectation")
                XCTAssert(items == self.expectedMovies, "Result items should match expectations")
            })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 5)
    }

    func testFetchSubscriptionSuccess() throws {
        let firstExp = expectation(description: "Fetch movies from CoreData")
        let secondExp = expectation(description: "Fetch movies again after CoreData context is updated")
        var resultCount = 0
        let result: AnyPublisher<[Movie], CoreDataRepositoryError> = try repository().fetchSubscription(fetchRequest)
        result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Not expecting completion since subscription finishes after subscriber cancel")
                default:
                    XCTFail("Not expecting failure")
                }
            }, receiveValue: { items in
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssert(items.count == 5, "Result items count should match expectation")
                    XCTAssert(items == self.expectedMovies, "Result items should match expectations")
                    firstExp.fulfill()
                case 2:
                    XCTAssert(items.count == 4, "Result items count should match expectation")
                    XCTAssert(items == Array(self.expectedMovies[0 ... 3]), "Result items should match expectations")
                    secondExp.fulfill()
                default:
                    XCTFail("Not expecting any values past the first two.")
                }

            })
            .store(in: &cancellables)
        wait(for: [firstExp], timeout: 5)
        try repositoryContext().performAndWait {
            do {
                let objectId = try container().persistentStoreCoordinator
                    .managedObjectID(forURIRepresentation: try XCTUnwrap(expectedMovies.last?.url))
                try repositoryContext().delete(try repositoryContext().object(with: try XCTUnwrap(objectId)))
                try repositoryContext().save()
            } catch {
                XCTFail("Failed to update repository: \(error.localizedDescription)")
            }
        }
        wait(for: [secondExp], timeout: 5)
    }
}
