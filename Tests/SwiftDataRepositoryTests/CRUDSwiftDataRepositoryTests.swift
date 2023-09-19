// CRUDSwiftDataRepositoryTests.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CustomDump
import Foundation
import SwiftData
import SwiftDataRepository
import XCTest

final class CRUDSwiftDataRepositoryTests: SwiftDataXCTestCase {
    func testCreateSuccess() async throws {
        let movie = Movie(id: UUID(), title: "Create Success", releaseDate: Date(), boxOffice: 100)
        let createMovie = try await repository().create(movie).get()

        try await verify(createMovie)
    }

    func testReadSuccess() async throws {
        let movie = Movie(id: UUID(), title: "Read Success", releaseDate: Date(), boxOffice: 100)
        try await context().insert(movie.asPersistentModel(in: context()))
        try await context().save()
        let identifier = try await identifier(for: movie)
        let readMovie: Movie = try await repository().read(identifier: identifier, as: Movie.self).get()
        XCTAssertNotNil(readMovie.persistentId)
        XCTAssertEqual(movie.id, readMovie.id)
    }

    func testUpdateSuccess() async throws {
        let movie = Movie(
            id: UUID(),
            title: "Update Success",
            releaseDate: Date(timeIntervalSinceReferenceDate: 0),
            boxOffice: 100
        )
        try await context().insert(movie.asPersistentModel(in: context()))
        try await context().save()
        var _updatedMovie = movie
        _updatedMovie.releaseDate = Date.distantFuture
        _updatedMovie.persistentId = try await identifier(for: movie)

        let updatedMovie = try await repository().update(_updatedMovie).get()
        XCTAssertEqual(_updatedMovie, updatedMovie)
    }

    func testDeleteSuccess() async throws {
        var movie = Movie(id: UUID(), title: "Delete Success", releaseDate: Date(), boxOffice: 100)
        try await context().insert(movie.asPersistentModel(in: context()))
        try await context().save()
        let identifier = try await identifier(for: movie)
        movie.persistentId = identifier
        _ = try await repository().delete(identifier: identifier).get()
        try await verifyDoesNotExist(movie)
    }

    func testReadSubscriptionSuccess() async throws {
        var movie = Movie(id: UUID(), title: "Read Success", releaseDate: Date(), boxOffice: 100)

        let count = try await context().fetchCount(FetchDescriptor<RepoMovie>())

        XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

        let repoMoviePersistentId: PersistentIdentifier = try await { [self] in
            let repoMovie = try await movie.asPersistentModel(in: context())
            try await context().save()
            return repoMovie.persistentModelID
        }()

        movie.persistentId = repoMoviePersistentId
        let countAfterCreate: Int = try await context().fetchCount(FetchDescriptor<RepoMovie>())
        XCTAssertEqual(countAfterCreate, 1, "Count of objects in CoreData should be 1 for read test.")

        var editedMovie = movie
        editedMovie.title = "New Title"

        let firstExp = expectation(description: "Read a movie from CoreData")
        let secondExp = expectation(description: "Read a movie again after CoreData context is updated")

        let subscriptionTask = Task {
            var resultCount = 0
            for await receiveResult in try await repository().readSubscription(
                identifier: repoMoviePersistentId,
                as: Movie.self
            ) {
                let receiveMovie = try receiveResult.get()
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
            }
        }
        await fulfillment(of: [firstExp], timeout: 5)
        guard let editedRepoMovie = try await context().model(for: repoMoviePersistentId) as? RepoMovie else {
            XCTFail()
            return
        }
        editedMovie.updating(persisted: editedRepoMovie)
        try await repository().saveContext()
        await fulfillment(of: [secondExp], timeout: 5)
        subscriptionTask.cancel()
    }
}

extension SwiftDataRepository {
    func saveContext() async throws {
        try context.save()
    }
}
