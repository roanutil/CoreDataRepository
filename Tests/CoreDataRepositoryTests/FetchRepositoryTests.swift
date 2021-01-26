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
        ("testFetchSuccess", testFetchSuccess)
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
}
