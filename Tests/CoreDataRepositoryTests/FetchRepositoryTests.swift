//
//  FetchRepositoryTests.swift
//  
//
//  Created by Andrew Roan on 1/22/21.
//

import CoreData
import Combine
import XCTest
@testable import CoreDataRepository

final class FetchRepositoryTests: CoreDataXCTestCase {

    static var allTests = [
        ("testFetchSuccess", testFetchSuccess),
        ("testFetchSubscriptionSuccess", testFetchSubscriptionSuccess)
    ]

    typealias Success = FetchRepository.Success<Movie>
    typealias Failure = FetchRepository.Failure<Movie>

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
    var _repository: FetchRepository?
    var repository: FetchRepository { _repository! }

    override func setUp() {
        super.setUp()
        self._repository = FetchRepository(context: self.backgroundContext)
        _ = movies.map { $0.asRepoManaged(in: viewContext) }
        try? viewContext.save()
        expectedMovies = try! viewContext.fetch(fetchRequest).map { $0.asUnmanaged }
    }

    override func tearDown() {
        super.tearDown()
        self._repository = nil
        expectedMovies = []
    }

    func testFetchSuccess() {
        let exp = expectation(description: "Fetch movies from CoreData")
        let result: AnyPublisher<Success, Failure> = repository.fetch(fetchRequest)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    exp.fulfill()
                default:
                    XCTFail("Not expecting failure")
                }
        }, receiveValue: { value in
            assert(value.items.count == 5, "Result items count should match expectation")
            assert(value.items == self.expectedMovies, "Result items should match expectations")
        })
        wait(for: [exp], timeout: 5)
    }

    func testFetchSubscriptionSuccess() {
        let firstExp = expectation(description: "Fetch movies from CoreData")
        let secondExp = expectation(description: "Fetch movies again after CoreData context is updated")
        var resultCount = 0
        let result: AnyPublisher<Success, Failure> = repository.fetch(fetchRequest).subscription(repository)
        let cancellable = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Not expecting completion since subscription finishes after subscriber cancel")
                default:
                    XCTFail("Not expecting failure")
                }
        }, receiveValue: { value in
            resultCount += 1
            switch resultCount {
            case 1:
                assert(value.items.count == 5, "Result items count should match expectation")
                assert(value.items == self.expectedMovies, "Result items should match expectations")
                firstExp.fulfill()
            case 2:
                assert(value.items.count == 4, "Result items count should match expectation")
                assert(value.items == Array(self.expectedMovies[0...3]), "Result items should match expectations")
                secondExp.fulfill()
            default:
                XCTFail("Not expecting any values past the first two.")
            }
            
        })
        wait(for: [firstExp], timeout: 5)
        let crudRepository = CRUDRepository(context: self.backgroundContext)
        let _: AnyPublisher<CRUDRepository.Success<Movie>, CRUDRepository.Failure<Movie>> = crudRepository.delete(self.expectedMovies.last!.objectID!)
        wait(for: [secondExp], timeout: 5)
        cancellable.cancel()
    }
}
