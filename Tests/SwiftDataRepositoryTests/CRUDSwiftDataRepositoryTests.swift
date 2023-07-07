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
}
