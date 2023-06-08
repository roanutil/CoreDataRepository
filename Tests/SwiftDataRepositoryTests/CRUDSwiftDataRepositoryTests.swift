// CRUDRepositoryTests.swift
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

@MainActor
final class CRUDSwiftDataRepositoryTests: SwiftDataXCTestCase {
    func testCreateSuccess() async throws {
        let movie = Movie(id: UUID(), title: "Create Success", releaseDate: Date(), boxOffice: 100)
        let createMovie = try await repository().create(movie).get()
        let readMovie = try await repository().read(identifier: XCTUnwrap(createMovie.persistentId), as: Movie.self)
            .get()
        XCTAssertEqual(movie.id, readMovie.id)
        XCTAssertNotNil(readMovie.persistentId)
        XCTAssertNotNil(createMovie.persistentId)
        XCTAssertEqual(createMovie.persistentId, readMovie.persistentId)
    }

    func testReadSuccess() async throws {
        let movie = Movie(id: UUID(), title: "Create Success", releaseDate: Date(), boxOffice: 100)
        try context().insert(movie.asPersistentModel(in: context()))
        try context().save()
        let identifier = try identifier(for: movie)
        let readMovie: Movie = try await repository().read(identifier: identifier, as: Movie.self).get()
        XCTAssertNotNil(readMovie.persistentId)
        XCTAssertEqual(movie.id, readMovie.id)
    }
}
