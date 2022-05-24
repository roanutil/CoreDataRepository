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
    var _repository: CoreDataRepository?
    var repository: CoreDataRepository { _repository! }

    override func setUpWithError() throws {
        try super.setUpWithError()
        _repository = CoreDataRepository(context: viewContext)
        _ = movies.map { $0.asRepoManaged(in: viewContext) }
        try viewContext.save()
        expectedMovies = try viewContext.fetch(fetchRequest).map(\.asUnmanaged)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        _repository = nil
        expectedMovies = []
    }

    func testFetchSuccess() throws {
        let exp = expectation(description: "Fetch movies from CoreData")
        let result: AnyPublisher<[Movie], CoreDataRepositoryError> = repository.fetch(fetchRequest)
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
        let result: AnyPublisher<[Movie], CoreDataRepositoryError> = repository.fetchSubscription(fetchRequest)
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
        let crudRepository = CoreDataRepository(context: viewContext)
        let _: AnyPublisher<Void, CoreDataRepositoryError> = crudRepository
            .delete(try XCTUnwrap(expectedMovies.last?.url))
        wait(for: [secondExp], timeout: 5)
    }
}
