// CRUDRepositoryTests.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import Combine
import CoreData
import CoreDataRepository
import CustomDump
import XCTest

final class CRUDRepositoryTests: CoreDataXCTestCase {
    func testCreateSuccess() async throws {
        let movie = Movie(id: UUID(), title: "Create Success", releaseDate: Date(), boxOffice: 100)
        let result: Result<Movie, CoreDataRepositoryError> = try await repository().create(movie)
        guard case var .success(resultMovie) = result else {
            XCTFail("Not expecting a failed result")
            return
        }

        XCTAssertNotNil(resultMovie.url)
        resultMovie.url = nil
        let diff = CustomDump.diff(resultMovie, movie)
        XCTAssertNil(diff)
    }

    func testReadSuccess() async throws {
        let movie = Movie(id: UUID(), title: "Read Success", releaseDate: Date(), boxOffice: 100)
        let createdMovie: Movie = try await repositoryContext().perform(schedule: .immediate) {
            let object = RepoMovie(context: try self.repositoryContext())
            object.create(from: movie)
            try self.repositoryContext().save()
            return object.asUnmanaged
        }

        let result: Result<Movie, CoreDataRepositoryError> = try await repository()
            .read(try XCTUnwrap(createdMovie.url))

        guard case var .success(resultMovie) = result else {
            XCTFail("Not expecting a failed result")
            return
        }

        XCTAssertNotNil(resultMovie.url)
        resultMovie.url = nil
        let diff = CustomDump.diff(resultMovie, movie)
        XCTAssertNil(diff)
    }

    func testReadFailure() async throws {
        let movie = Movie(id: UUID(), title: "Read Failure", releaseDate: Date(), boxOffice: 100)
        let createdMovie: Movie = try await repositoryContext().perform {
            let object = RepoMovie(context: try self.repositoryContext())
            object.create(from: movie)
            try self.repositoryContext().save()
            return object.asUnmanaged
        }
        _ = try await repositoryContext().perform {
            let objectID = try self.repositoryContext().persistentStoreCoordinator?
                .managedObjectID(forURIRepresentation: try XCTUnwrap(createdMovie.url))
            let object = try self.repositoryContext().existingObject(with: try XCTUnwrap(objectID))
            try self.repositoryContext().delete(object)
            try self.repositoryContext().save()
        }

        let result: Result<Movie, CoreDataRepositoryError> = try await repository()
            .read(try XCTUnwrap(createdMovie.url))

        switch result {
        case .success:
            XCTFail("Not expecting a successful result")
        case .failure:
            XCTAssert(true)
        }
    }

    func testUpdateSuccess() async throws {
        var movie = Movie(id: UUID(), title: "Update Success", releaseDate: Date(), boxOffice: 100)
        let createdMovie: Movie = try await repositoryContext().perform(schedule: .immediate) {
            let object = RepoMovie(context: try self.repositoryContext())
            object.create(from: movie)
            try self.repositoryContext().save()
            return object.asUnmanaged
        }

        movie.title = "Update Success - Edited"

        let result: Result<Movie, CoreDataRepositoryError> = try await repository()
            .update(try XCTUnwrap(createdMovie.url), with: movie)

        guard case var .success(resultMovie) = result else {
            XCTFail("Not expecting a failed result")
            return
        }

        XCTAssertNotNil(resultMovie.url)
        resultMovie.url = nil
        let diff = CustomDump.diff(resultMovie, movie)
        XCTAssertNil(diff)
    }

    func testUpdateFailure() async throws {
        var movie = Movie(id: UUID(), title: "Update Success", releaseDate: Date(), boxOffice: 100)
        let createdMovie: Movie = try await repositoryContext().perform(schedule: .immediate) {
            let object = RepoMovie(context: try self.repositoryContext())
            object.create(from: movie)
            try self.repositoryContext().save()
            return object.asUnmanaged
        }

        _ = try await repositoryContext().perform {
            let objectID = try self.repositoryContext().persistentStoreCoordinator?
                .managedObjectID(forURIRepresentation: try XCTUnwrap(createdMovie.url))
            let object = try self.repositoryContext().existingObject(with: try XCTUnwrap(objectID))
            try self.repositoryContext().delete(object)
            try self.repositoryContext().save()
        }

        movie.title = "Update Success - Edited"

        let result: Result<Movie, CoreDataRepositoryError> = try await repository()
            .update(try XCTUnwrap(createdMovie.url), with: movie)

        switch result {
        case .success:
            XCTFail("Not expecting a successful result")
        case .failure:
            XCTAssert(true)
        }
    }

    func testDeleteSuccess() async throws {
        let movie = Movie(id: UUID(), title: "Delete Success", releaseDate: Date(), boxOffice: 100)
        let createdMovie: Movie = try await repositoryContext().perform(schedule: .immediate) {
            let object = RepoMovie(context: try self.repositoryContext())
            object.create(from: movie)
            try self.repositoryContext().save()
            return object.asUnmanaged
        }

        let result: Result<Void, CoreDataRepositoryError> = try await repository()
            .delete(try XCTUnwrap(createdMovie.url))

        switch result {
        case .success:
            XCTAssert(true)
        case .failure:
            XCTFail("Not expecting a failed result")
        }
    }

    func testDeleteFailure() async throws {
        let movie = Movie(id: UUID(), title: "Delete Failure", releaseDate: Date(), boxOffice: 100)
        let createdMovie: Movie = try await repositoryContext().perform(schedule: .immediate) {
            let object = RepoMovie(context: try self.repositoryContext())
            object.create(from: movie)
            try self.repositoryContext().save()
            return object.asUnmanaged
        }

        _ = try await repositoryContext().perform {
            let objectID = try self.repositoryContext().persistentStoreCoordinator?
                .managedObjectID(forURIRepresentation: try XCTUnwrap(createdMovie.url))
            let object = try self.repositoryContext().existingObject(with: try XCTUnwrap(objectID))
            try self.repositoryContext().delete(object)
            try self.repositoryContext().save()
        }

        let result: Result<Void, CoreDataRepositoryError> = try await repository()
            .delete(try XCTUnwrap(createdMovie.url))

        switch result {
        case .success:
            XCTFail("Not expecting a success result")
        case .failure:
            XCTAssert(true)
        }
    }

    func testReadSubscriptionSuccess() async throws {
        var movie = Movie(id: UUID(), title: "Read Success", releaseDate: Date(), boxOffice: 100)

        let count: Int = try await repositoryContext().perform { [self] in
            try self.repositoryContext().count(for: RepoMovie.fetchRequest())
        }

        XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

        let repoMovieUrl: URL = try await repositoryContext().perform { [self] in
            let repoMovie = movie.asRepoManaged(in: try self.repositoryContext())
            try self.repositoryContext().save()
            return repoMovie.objectID.uriRepresentation()
        }

        movie.url = repoMovieUrl
        let countAfterCreate: Int = try await repositoryContext().perform {
            try self.repositoryContext().count(for: RepoMovie.fetchRequest())
        }
        XCTAssertEqual(countAfterCreate, 1, "Count of objects in CoreData should be 1 for read test.")

        var editedMovie = movie
        editedMovie.title = "New Title"

        let firstExp = expectation(description: "Read a movie from CoreData")
        let secondExp = expectation(description: "Read a movie again after CoreData context is updated")
        var resultCount = 0
        let result: AnyPublisher<Movie, CoreDataRepositoryError> = try repository()
            .readSubscription(try XCTUnwrap(movie.url))
        result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Not expecting completion since subscription finishes after subscriber cancel")
                case .failure:
                    XCTFail("Not expecting failure")
                }
            }, receiveValue: { receiveMovie in
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(receiveMovie, movie, "Success response should match local object.")
                    firstExp.fulfill()
                case 2:
                    XCTAssertEqual(receiveMovie, editedMovie, "Second success response should match local object.")
                    secondExp.fulfill()
                default:
                    XCTFail("Not expecting any values past the first two.")
                }

            })
            .store(in: &cancellables)
        wait(for: [firstExp], timeout: 5)
        try repositoryContext().performAndWait { [self] in
            let coordinator = try XCTUnwrap(try self.repositoryContext().persistentStoreCoordinator)
            let objectId = try XCTUnwrap(coordinator.managedObjectID(forURIRepresentation: try XCTUnwrap(movie.url)))
            let object = try XCTUnwrap(try repositoryContext().existingObject(with: objectId) as? RepoMovie)
            object.update(from: editedMovie)
            try self.repositoryContext().save()
        }
        wait(for: [secondExp], timeout: 5)
    }
}
