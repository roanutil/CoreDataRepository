//
//  BatchRepositoryTests.swift
//  
//
//  Created by Andrew Roan on 1/25/21.
//

import CoreData
import Combine
import XCTest
@testable import CoreDataRepository

class BatchRepositoryTests: CoreDataXCTestCase {

    static var allTests = [
        ("testInsertSuccess", testInsertSuccess),
        ("testInsertFailure", testInsertFailure),
        ("testUpdateSuccess", testUpdateSuccess),
        ("testDeleteSuccess", testDeleteSuccess)
    ]

    typealias Success = BatchRepository.Success
    typealias Failure = BatchRepository.Failure

    let movies: [[String: Any]] = [
        ["id": UUID(), "title": "A", "releaseDate": Date()],
        ["id": UUID(), "title": "B", "releaseDate": Date()],
        ["id": UUID(), "title": "C", "releaseDate": Date()],
        ["id": UUID(), "title": "D", "releaseDate": Date()],
        ["id": UUID(), "title": "E", "releaseDate": Date()]
    ]
    let failureMovies: [[String: Any]] = [
        ["id": "A", "title": 1, "releaseDate": "A"],
        ["id": "B", "title": 2, "releaseDate": "B"],
        ["id": "C", "title": 3, "releaseDate": "C"],
        ["id": "D", "title": 4, "releaseDate": "D"],
        ["id": "E", "title": 5, "releaseDate": "E"]
    ]
    var _repository: BatchRepository?
    var repository: BatchRepository { _repository! }

    override func setUp() {
        super.setUp()
        self._repository = BatchRepository(context: self.backgroundContext)
    }

    override func tearDown() {
        super.tearDown()
        self._repository = nil
    }

    func testInsertSuccess() {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? self.viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")

        let exp = expectation(description: "Successfully batch insert movies.")
        let request = NSBatchInsertRequest(entityName: RepoMovie.entity().name!, objects: self.movies)
        _ = self.repository.insert(request)
            .subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        exp.fulfill()
                    default:
                        XCTFail("Not expecting failure")
                    }
                },
                receiveValue: { value in
                    switch value {
                    case let .insert(resultRequest, _):
                        assert(resultRequest == request, "Requests should match")
                    default:
                        XCTFail("Received wrong value result")
                    }
                }
            )
        wait(for: [exp], timeout: 5)

        let data = try! self.viewContext.fetch(fetchRequest)
        assert(data.map { $0.title ?? "" }.sorted() == ["A", "B", "C", "D", "E"], "Inserted titles should match expectation")
    }

    func testInsertFailure() {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? self.viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")

        let exp = expectation(description: "Fail to batch insert movies.")
        let request = NSBatchInsertRequest(entityName: RepoMovie.entity().name!, objects: self.failureMovies)
        _ = self.repository.insert(request)
            .subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure:
                        exp.fulfill()
                    default:
                        XCTFail("Not expecting success")
                    }
                },
                receiveValue: { value in
                    switch value {
                    case let .insert(resultRequest, _):
                        assert(resultRequest == request, "Requests should match")
                    default:
                        XCTFail("Received wrong value result")
                    }
                }
            )
        wait(for: [exp], timeout: 5)

        let data = try! self.viewContext.fetch(fetchRequest)
        assert(data.map { $0.title ?? "" }.sorted() == [], "There should be no inserted values.")
    }

    func testUpdateSuccess() {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? self.viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")

        _ = self.movies.map { Movie(id: $0["id"] as! UUID, title: $0["title"] as! String, releaseDate: $0["releaseDate"] as! Date).asRepoManaged(in: self.viewContext) }
        try! self.viewContext.save()

        let exp = expectation(description: "Successfully batch update movies.")
        let predicate = NSPredicate(value: true)
        let request = NSBatchUpdateRequest(entityName: RepoMovie.entity().name!)
        request.predicate = predicate
        request.propertiesToUpdate = ["title": "Updated!"]
        _ = self.repository.update(request)
            .subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        exp.fulfill()
                    default:
                        XCTFail("Not expecting Failure")
                    }
                },
                receiveValue: { value in
                    switch value {
                    case let .update(resultRequest, _):
                        assert(resultRequest == request, "Requests should match")
                    default:
                        XCTFail("Received wrong value result")
                    }
                }
            )
        wait(for: [exp], timeout: 5)

        let data = try! self.viewContext.fetch(fetchRequest)
        assert(data.map { $0.title ?? "" }.sorted() == ["Updated!", "Updated!", "Updated!", "Updated!", "Updated!"], "Updated titles should match request")
    }

    // FIXME: Crashes instead of throwing an error
    /*
    func testUpdateFailure() {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? self.viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")

        _ = self.movies.map { Movie(id: $0["id"] as! UUID, title: $0["title"] as! String, releaseDate: $0["releaseDate"] as! Date).asRepoManaged(in: self.viewContext) }
        try! self.viewContext.save()

        let exp = expectation(description: "Fail to batch update movies.")
        let predicate = NSPredicate(value: true)
        let request = NSBatchUpdateRequest(entityName: RepoMovie.entity().name!)
        request.predicate = predicate
        request.propertiesToUpdate = ["title": "Updated!", "boxOffice": "Wrong type"]
        _ = self.repository.update(request)
            .subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure:
                        exp.fulfill()
                    default:
                        XCTFail("Not expecting success")
                    }
                },
                receiveValue: { value in
                    switch value {
                    case let .update(resultRequest, _):
                        assert(resultRequest == request, "Requests should match")
                    default:
                        XCTFail("Received wrong value result")
                    }
                }
            )
        wait(for: [exp], timeout: 5)

        let data = try! self.viewContext.fetch(fetchRequest)
        assert(data.map { $0.title }.sorted() == [], "There should be no updated values.")
    }
     */
    func testDeleteSuccess() {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? self.viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")

        _ = self.movies.map { Movie(id: $0["id"] as! UUID, title: $0["title"] as! String, releaseDate: $0["releaseDate"] as! Date).asRepoManaged(in: self.viewContext) }
        try! self.viewContext.save()

        let exp = expectation(description: "Successfully batch delete movies.")
        let request = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: RepoMovie.entity().name!))
        _ = self.repository.delete(request)
            .subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        exp.fulfill()
                    default:
                        XCTFail("Not expecting failure")
                    }
                },
                receiveValue: { value in
                    switch value {
                    case let .delete(resultRequest, _):
                        assert(resultRequest == request, "Requests should match")
                    default:
                        XCTFail("Received wrong value result")
                    }
                }
            )
        wait(for: [exp], timeout: 5)
        self.viewContext.reset()

        let data = try! self.viewContext.fetch(fetchRequest)
        assert(data.map { $0.title ?? "" }.sorted() == [], "There should be no inserted values.")
    }

    // FIXME: How to make it fail?
    /*func testDeleteFailure() {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? self.viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")

        let exp = expectation(description: "Fail to batch delete movies.")
        let request = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: RepoMovie.entity().name!))
        _ = self.repository.delete(request)
            .subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure:
                        exp.fulfill()
                    default:
                        XCTFail("Not expecting success")
                    }
                },
                receiveValue: { value in
                    switch value {
                    case let .delete(resultRequest, _):
                        assert(resultRequest == request, "Requests should match")
                    default:
                        XCTFail("Received wrong value result")
                    }
                }
            )
        wait(for: [exp], timeout: 5)

        let data = try! self.viewContext.fetch(fetchRequest)
        assert(data.map { $0.title }.sorted() == [], "There should be no inserted values.")
    }
 */
}
