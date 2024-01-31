// CRUDRepositoryTests.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import CoreDataRepository
import CustomDump
import XCTest

final class CRUDRepositoryTests: CoreDataXCTestCase {
    func testCreateSuccess() async throws {
        let historyTimeStamp = Date()
        let transactionAuthor: String = #function
        let movie = Movie(id: UUID(), title: "Create Success", releaseDate: Date(), boxOffice: 100)
        let result: Result<Movie, CoreDataError> = try await repository()
            .create(movie, transactionAuthor: transactionAuthor)
        guard case let .success(resultMovie) = result else {
            XCTFail("Not expecting a failed result")
            return
        }
        var tempResultMovie = resultMovie
        XCTAssertNotNil(tempResultMovie.url)
        tempResultMovie.url = nil
        XCTAssertNoDifference(tempResultMovie, movie)

        try await verify(resultMovie)
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreateFailure() async throws {
        let transactionAuthor: String = #function
        let movie = Movie(id: UUID(), title: "Create Success", releaseDate: Date(), boxOffice: 100)
        let existingMovie = try await repositoryContext().perform(schedule: .immediate) {
            let object = try ManagedMovie(context: self.repositoryContext())
            try movie.updating(managed: object)
            try self.repositoryContext().save()
            return try Movie(managed: object)
        }
        var tempResultMovie = existingMovie
        XCTAssertNotNil(tempResultMovie.url)
        tempResultMovie.url = nil
        XCTAssertNoDifference(tempResultMovie, movie)

        try await verify(existingMovie)

        let result: Result<Movie, CoreDataError> = try await repository()
            .create(movie, transactionAuthor: transactionAuthor)
        guard case .failure = result else {
            XCTFail("Expecting a failed result")
            return
        }
    }

    func testReadSuccess() async throws {
        let movie = Movie(id: UUID(), title: "Read Success", releaseDate: Date(), boxOffice: 100)
        let createdMovie: Movie = try await repositoryContext().perform(schedule: .immediate) {
            let object = try ManagedMovie(context: self.repositoryContext())
            try movie.updating(managed: object)
            try self.repositoryContext().save()
            return try Movie(managed: object)
        }

        let result: Result<Movie, CoreDataError> = try await repository()
            .read(XCTUnwrap(createdMovie.url), of: Movie.self)

        guard case let .success(resultMovie) = result else {
            XCTFail("Not expecting a failed result")
            return
        }

        var tempResultMovie = resultMovie

        XCTAssertNotNil(tempResultMovie.url)
        tempResultMovie.url = nil
        XCTAssertNoDifference(tempResultMovie, movie)

        try await verify(resultMovie)
    }

    func testReadFailure() async throws {
        let movie = Movie(id: UUID(), title: "Read Failure", releaseDate: Date(), boxOffice: 100)
        let createdMovie: Movie = try await repositoryContext().perform {
            let object = try ManagedMovie(context: self.repositoryContext())
            try movie.updating(managed: object)
            try self.repositoryContext().save()
            return try Movie(managed: object)
        }
        _ = try await repositoryContext().perform {
            let objectID = try self.repositoryContext().persistentStoreCoordinator?
                .managedObjectID(forURIRepresentation: XCTUnwrap(createdMovie.url))
            let object = try self.repositoryContext().existingObject(with: XCTUnwrap(objectID))
            try self.repositoryContext().delete(object)
            try self.repositoryContext().save()
        }

        let result: Result<Movie, CoreDataError> = try await repository()
            .read(XCTUnwrap(createdMovie.url), of: Movie.self)

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
            let object = try ManagedMovie(context: self.repositoryContext())
            try movie.updating(managed: object)
            try self.repositoryContext().save()
            return try Movie(managed: object)
        }

        movie.title = "Update Success - Edited"

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let result: Result<Movie, CoreDataError> = try await repository()
            .update(XCTUnwrap(createdMovie.url), with: movie, transactionAuthor: transactionAuthor)

        guard case let .success(resultMovie) = result else {
            XCTFail("Not expecting a failed result")
            return
        }

        var tempResultMovie = resultMovie

        XCTAssertNotNil(tempResultMovie.url)
        tempResultMovie.url = nil
        XCTAssertNoDifference(tempResultMovie, movie)

        try await verify(resultMovie)
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testUpdateFailure() async throws {
        var movie = Movie(id: UUID(), title: "Update Success", releaseDate: Date(), boxOffice: 100)
        let createdMovie: Movie = try await repositoryContext().perform(schedule: .immediate) {
            let object = try ManagedMovie(context: self.repositoryContext())
            try movie.updating(managed: object)
            try self.repositoryContext().save()
            return try Movie(managed: object)
        }

        _ = try await repositoryContext().perform {
            let objectID = try self.repositoryContext().persistentStoreCoordinator?
                .managedObjectID(forURIRepresentation: XCTUnwrap(createdMovie.url))
            let object = try self.repositoryContext().existingObject(with: XCTUnwrap(objectID))
            try self.repositoryContext().delete(object)
            try self.repositoryContext().save()
        }

        movie.title = "Update Success - Edited"

        let result: Result<Movie, CoreDataError> = try await repository()
            .update(XCTUnwrap(createdMovie.url), with: movie)

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
            let object = try ManagedMovie(context: self.repositoryContext())
            try movie.updating(managed: object)
            try self.repositoryContext().save()
            return try Movie(managed: object)
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let result: Result<Void, CoreDataError> = try await repository()
            .delete(XCTUnwrap(createdMovie.url), transactionAuthor: transactionAuthor)

        switch result {
        case .success:
            XCTAssert(true)
        case .failure:
            XCTFail("Not expecting a failed result")
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDeleteFailure() async throws {
        let movie = Movie(id: UUID(), title: "Delete Failure", releaseDate: Date(), boxOffice: 100)
        let createdMovie: Movie = try await repositoryContext().perform(schedule: .immediate) {
            let object = try ManagedMovie(context: self.repositoryContext())
            try movie.updating(managed: object)
            try self.repositoryContext().save()
            return try Movie(managed: object)
        }

        _ = try await repositoryContext().perform {
            let objectID = try self.repositoryContext().persistentStoreCoordinator?
                .managedObjectID(forURIRepresentation: XCTUnwrap(createdMovie.url))
            let object = try self.repositoryContext().existingObject(with: XCTUnwrap(objectID))
            try self.repositoryContext().delete(object)
            try self.repositoryContext().save()
        }

        let result: Result<Void, CoreDataError> = try await repository()
            .delete(XCTUnwrap(createdMovie.url))

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
            try repositoryContext().count(for: Movie.managedFetchRequest())
        }

        XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

        let managedMovieUrl: URL = try await repositoryContext().perform { [self] in
            let managedMovie = try movie.asManagedModel(in: repositoryContext())
            try repositoryContext().save()
            return managedMovie.objectID.uriRepresentation()
        }

        movie.url = managedMovieUrl
        let countAfterCreate: Int = try await repositoryContext().perform {
            try self.repositoryContext().count(for: Movie.managedFetchRequest())
        }
        XCTAssertEqual(countAfterCreate, 1, "Count of objects in CoreData should be 1 for read test.")

        var editedMovie = movie
        editedMovie.title = "New Title"

        let task = Task { [movie, editedMovie] in
            var resultCount = 0
            let stream = try repository().readSubscription(managedMovieUrl, of: Movie.self)
            for await _movie in stream {
                let receivedMovie = try _movie.get()
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(receivedMovie, movie, "Success response should match local object.")
                    let crudRepository = try TestCoreDataRepository(context: repositoryContext())
                    let _: Result<Movie, CoreDataError> = await crudRepository
                        .update(managedMovieUrl, with: editedMovie)
                    await Task.yield()
                case 2:
                    XCTAssertEqual(receivedMovie, editedMovie, "Second success response should match local object.")
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

    func testReadThrowingSubscriptionSuccess() async throws {
        var movie = Movie(id: UUID(), title: "Read Success", releaseDate: Date(), boxOffice: 100)

        let count: Int = try await repositoryContext().perform { [self] in
            try repositoryContext().count(for: Movie.managedFetchRequest())
        }

        XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

        let managedMovieUrl: URL = try await repositoryContext().perform { [self] in
            let managedMovie = try movie.asManagedModel(in: repositoryContext())
            try repositoryContext().save()
            return managedMovie.objectID.uriRepresentation()
        }

        movie.url = managedMovieUrl
        let countAfterCreate: Int = try await repositoryContext().perform {
            try self.repositoryContext().count(for: Movie.managedFetchRequest())
        }
        XCTAssertEqual(countAfterCreate, 1, "Count of objects in CoreData should be 1 for read test.")

        var editedMovie = movie
        editedMovie.title = "New Title"

        let task = Task { [movie, editedMovie] in
            var resultCount = 0
            let stream = try repository().readThrowingSubscription(managedMovieUrl, of: Movie.self)
            for try await receivedMovie in stream {
                resultCount += 1
                switch resultCount {
                case 1:
                    XCTAssertEqual(receivedMovie, movie, "Success response should match local object.")
                    let crudRepository = try TestCoreDataRepository(context: repositoryContext())
                    let _: Result<Movie, CoreDataError> = await crudRepository
                        .update(managedMovieUrl, with: editedMovie)
                    await Task.yield()
                case 2:
                    XCTAssertEqual(receivedMovie, editedMovie, "Second success response should match local object.")
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
