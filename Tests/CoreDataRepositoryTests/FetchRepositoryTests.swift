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
        expectedMovies = try repositoryContext().performAndWait {
            _ = try self.movies.map { $0.asRepoManaged(in: try repositoryContext()) }
            try self.repositoryContext().save()
            return try self.repositoryContext().fetch(fetchRequest).map(\.asUnmanaged)
        }
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        expectedMovies = []
    }

    func testFetchSuccess() async throws {
        let result: Result<[Movie], CoreDataRepositoryError> = try await repository().fetch(fetchRequest)
        switch result {
        case let .success(movies):
            XCTAssertEqual(movies.count, 5, "Result items count should match expectation")
            XCTAssertEqual(movies, expectedMovies, "Result items should match expectations")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testFetchSubscriptionSuccess() async throws {
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
                    XCTAssertEqual(items.count, 5, "Result items count should match expectation")
                    XCTAssertEqual(items, self.expectedMovies, "Result items should match expectations")
                    firstExp.fulfill()
                case 2:
                    XCTAssertEqual(items.count, 4, "Result items count should match expectation")
                    XCTAssertEqual(items, Array(self.expectedMovies[0 ... 3]), "Result items should match expectations")
                    secondExp.fulfill()
                default:
                    XCTFail("Not expecting any values past the first two.")
                }

            })
            .store(in: &cancellables)
        wait(for: [firstExp], timeout: 5)
        let crudRepository = CoreDataRepository(context: try repositoryContext())
        _ = try await repositoryContext().perform { [self] in
            let url = try XCTUnwrap(expectedMovies.last?.url)
            let coordinator = try XCTUnwrap(try repositoryContext().persistentStoreCoordinator)
            let objectId = try XCTUnwrap(coordinator.managedObjectID(forURIRepresentation: url))
            let object = try repositoryContext().existingObject(with: objectId)
            try repositoryContext().delete(object)
            try repositoryContext().save()
        }
        let _: Result<Void, CoreDataRepositoryError> = await crudRepository
            .delete(try XCTUnwrap(expectedMovies.last?.url))
        wait(for: [secondExp], timeout: 5)
    }
}
