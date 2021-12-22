// CRUDRepositoryTests.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2021 Andrew Roan

import Combine
import CoreData
@testable import CoreDataRepository
import XCTest

class CRUDRepositoryTests: CoreDataXCTestCase {
    static var allTests = [
        ("testCreateSuccess", testCreateSuccess),
        ("testReadSuccess", testReadSuccess),
        ("testReadFailure", testReadFailure),
        ("testUpdateSuccess", testUpdateSuccess),
        ("testUpdateFailure", testUpdateFailure),
        ("testDeleteSuccess", testDeleteSuccess),
        ("testDeleteFailure", testDeleteFailure),
    ]
    typealias Success = CRUDRepository.Success<Movie>
    typealias Failure = CRUDRepository.Failure<Movie>

    var _repository: CRUDRepository?
    var repository: CRUDRepository { _repository! }

    override func setUp() {
        super.setUp()
        _repository = CRUDRepository(context: backgroundContext)
    }

    override func tearDown() {
        super.tearDown()
        _repository = nil
    }

    func testCreateSuccess() {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")

        let exp = expectation(description: "Create a RepoMovie in CoreData")
        var movie = Movie(id: UUID(), title: "Create Success", releaseDate: Date(), boxOffice: 100)
        _ = repository.create(movie).subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        exp.fulfill()
                    case .failure:
                        XCTFail("Received failure from CRUDRepository.create")
                    }
                },
                receiveValue: { result in
                    switch result {
                    case let .create(resultMovie):
                        assert(resultMovie == movie, "Success response should match local object.")
                    default:
                        fatalError()
                    }
                }
            )
        wait(for: [exp], timeout: 5)

        let all = ((try? viewContext.fetch(RepoMovie.fetchRequest())) ?? []).map(\.asUnmanaged)
        assert(all.count == 1, "There should be only one CoreData object after creating one.")
        let fetchedMovie = all.first!
        assert(fetchedMovie.objectID != nil, "CoreData object should have NSManagedObjectID")
        movie.objectID = fetchedMovie.objectID
        assert(fetchedMovie == movie, "CoreData object should match the one created.")
    }

    func testReadSuccess() {
        var movie = Movie(id: UUID(), title: "Read Success", releaseDate: Date(), boxOffice: 100)
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")
        let repoMovie = movie.asRepoManaged(in: viewContext)
        try? viewContext.save()
        movie.objectID = repoMovie.objectID
        let countAfterCreate = try? viewContext.count(for: RepoMovie.fetchRequest())
        assert(countAfterCreate == 1, "Count of objects in CoreData should be 1 for read test.")

        let exp = expectation(description: "Read a RepoMovie in CoreData")
        let result: AnyPublisher<Success, Failure> = repository.read(movie.objectID!)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        exp.fulfill()
                    case .failure:
                        XCTFail("Received failure from CRUDRepository.read")
                    }
                },
                receiveValue: { result in
                    switch result {
                    case let .read(receiveMovie):
                        assert(receiveMovie == movie, "Success response should match local object.")
                    default:
                        fatalError()
                    }
                }
            )
        wait(for: [exp], timeout: 5)
    }

    func testReadFailure() {
        var movie = Movie(id: UUID(), title: "Read Failure", releaseDate: Date(), boxOffice: 100)
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")
        let repoMovie = movie.asRepoManaged(in: viewContext)
        try? viewContext.save()
        movie.objectID = repoMovie.objectID
        let countAfterCreate = try? viewContext.count(for: RepoMovie.fetchRequest())
        assert(countAfterCreate == 1, "Count of objects in CoreData should be 1 for read test.")

        viewContext.delete(repoMovie)
        try? viewContext.save()

        let exp = expectation(description: "Fail to read a RepoMovie in CoreData")
        let result: AnyPublisher<Success, Failure> = repository.read(movie.objectID!)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Received success from CRUDRepository.read when expecting failure.")
                    case .failure:
                        exp.fulfill()
                    }
                },
                receiveValue: { _ in XCTFail("Not expected to receive a value for CRUDRepository.read") }
            )
        wait(for: [exp], timeout: 5)
    }

    func testUpdateSuccess() {
        var movie = Movie(id: UUID(), title: "Update Success", releaseDate: Date(), boxOffice: 100)
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try! viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")
        let repoMovie = movie.asRepoManaged(in: viewContext)
        try! viewContext.save()
        movie.objectID = repoMovie.objectID
        let countAfterCreate = try! viewContext.count(for: RepoMovie.fetchRequest())
        assert(countAfterCreate == 1, "Count of objects in CoreData should be 1 for read test.")

        movie.title = "Update Success - Edited"

        let exp = expectation(description: "Read a RepoMovie in CoreData")
        let result: AnyPublisher<Success, Failure> = repository.update(movie.objectID!, with: movie)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        exp.fulfill()
                    case .failure:
                        XCTFail("Received failure from CRUDRepository.update")
                    }
                },
                receiveValue: { result in
                    switch result {
                    case let .update(resultMovie):
                        assert(resultMovie == movie, "Success response should match local object.")
                    default:
                        fatalError()
                    }
                }
            )
        wait(for: [exp], timeout: 10)

        let updatedRepoMovie = try! viewContext.existingObject(with: movie.objectID!)
        let updatedMovie = (updatedRepoMovie as! RepoMovie).asUnmanaged
        assert(updatedMovie == movie, "CoreData movie should be updated with the new title.")
    }

    func testUpdateFailure() {
        var movie = Movie(id: UUID(), title: "Update Failure", releaseDate: Date(), boxOffice: 100)
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")
        let repoMovie = movie.asRepoManaged(in: viewContext)
        try? viewContext.save()
        movie.objectID = repoMovie.objectID
        let countAfterCreate = try? viewContext.count(for: fetchRequest)
        assert(countAfterCreate == 1, "Count of objects in CoreData should be 1 for read test.")

        viewContext.delete(repoMovie)
        try! viewContext.save()

        let countAfterDelete = try? viewContext.count(for: fetchRequest)
        assert(countAfterDelete == 0, "Count of objects in CoreData should be 0 after delete for read test.")

        let exp = expectation(description: "Fail to update a RepoMovie in CoreData")
        let result: AnyPublisher<Success, Failure> = repository.update(movie.objectID!, with: movie)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Received success from CRUDRepository.update when expecting failure.")
                    case .failure:
                        exp.fulfill()
                    }
                },
                receiveValue: { _ in XCTFail("Not expected to receive a value for CRUDRepository.update") }
            )
        wait(for: [exp], timeout: 10)
    }

    func testDeleteSuccess() {
        var movie = Movie(id: UUID(), title: "Delete Success", releaseDate: Date(), boxOffice: 100)
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")
        let repoMovie = movie.asRepoManaged(in: viewContext)
        try? viewContext.save()
        movie.objectID = repoMovie.objectID
        let countAfterCreate = try? viewContext.count(for: RepoMovie.fetchRequest())
        assert(countAfterCreate == 1, "Count of objects in CoreData should be 1 for read test.")

        let exp = expectation(description: "Read a RepoMovie in CoreData")
        let result: AnyPublisher<Success, Failure> = repository.delete(movie.objectID!)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        exp.fulfill()
                    case .failure:
                        XCTFail("Received failure from CRUDRepository.delete")
                    }
                },
                receiveValue: { result in
                    switch result {
                    case let .delete(resultMovie):
                        assert(resultMovie == movie.objectID, "Success response should match local object.")
                    default:
                        fatalError()
                    }
                }
            )
        wait(for: [exp], timeout: 5)

        let afterDeleteCount = try? viewContext.count(for: fetchRequest)
        assert(afterDeleteCount == 0, "CoreData should have no objects after delete")
    }

    func testDeleteFailure() {
        var movie = Movie(id: UUID(), title: "Delete Failure", releaseDate: Date(), boxOffice: 100)
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        let count = try? viewContext.count(for: fetchRequest)
        assert(count == 0, "Count of objects in CoreData should be zero at the start of each test.")
        let repoMovie = movie.asRepoManaged(in: viewContext)
        try? viewContext.save()
        movie.objectID = repoMovie.objectID
        let countAfterCreate = try? viewContext.count(for: fetchRequest)
        assert(countAfterCreate == 1, "Count of objects in CoreData should be 1 for delete test.")

        viewContext.delete(repoMovie)
        try? viewContext.save()

        let exp = expectation(description: "Fail to delete a RepoMovie in CoreData")
        let result: AnyPublisher<Success, Failure> = repository.delete(movie.objectID!)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Received success from CRUDRepository.delete when expecting failure.")
                    case .failure:
                        exp.fulfill()
                    }
                },
                receiveValue: { _ in XCTFail("Not expected to receive a value for CRUDRepository.delete") }
            )
        wait(for: [exp], timeout: 5)
    }
}
