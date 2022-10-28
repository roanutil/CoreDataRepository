// BatchRepositoryTests.swift
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

final class BatchRepositoryTests: CoreDataXCTestCase {
    let movies: [[String: Any]] = [
        ["id": UUID(), "title": "A", "releaseDate": Date()],
        ["id": UUID(), "title": "B", "releaseDate": Date()],
        ["id": UUID(), "title": "C", "releaseDate": Date()],
        ["id": UUID(), "title": "D", "releaseDate": Date()],
        ["id": UUID(), "title": "E", "releaseDate": Date()],
    ]
    let failureInsertMovies: [[String: Any]] = [
        ["id": "A", "title": 1, "releaseDate": "A"],
        ["id": "B", "title": 2, "releaseDate": "B"],
        ["id": "C", "title": 3, "releaseDate": "C"],
        ["id": "D", "title": 4, "releaseDate": "D"],
        ["id": "E", "title": 5, "releaseDate": "E"],
    ]
    let failureCreateMovies: [[String: Any]] = {
        let id = UUID()
        return [
            ["id": id, "title": "A", "releaseDate": Date()],
            ["id": id, "title": "B", "releaseDate": Date()],
            ["id": id, "title": "C", "releaseDate": Date()],
            ["id": id, "title": "D", "releaseDate": Date()],
            ["id": id, "title": "E", "releaseDate": Date()],
        ]
    }()

    func mapDictToRepoMovie(_ dict: [String: Any]) throws -> RepoMovie {
        try mapDictToMovie(dict)
            .asRepoManaged(in: try repositoryContext())
    }

    func mapDictToMovie(_ dict: [String: Any]) throws -> Movie {
        let id = try XCTUnwrap(dict["id"] as? UUID)
        let title = try XCTUnwrap(dict["title"] as? String)
        let releaseDate = try XCTUnwrap(dict["releaseDate"] as? Date)
        return Movie(id: id, title: title, releaseDate: releaseDate)
    }

    func testInsertSuccess() async throws {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let request = NSBatchInsertRequest(entityName: try XCTUnwrap(RepoMovie.entity().name), objects: movies)
        let result: Result<NSBatchInsertResult, CoreDataRepositoryError> = try await repository().insert(request)

        switch result {
        case .success:
            XCTAssert(true)
        case .failure:
            XCTFail("Not expecting a failure result")
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map { $0.title ?? "" }.sorted(),
                ["A", "B", "C", "D", "E"],
                "Inserted titles should match expectation"
            )
        }
    }

    func testInsertFailure() async throws {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let request = NSBatchInsertRequest(
            entityName: try XCTUnwrap(RepoMovie.entity().name),
            objects: failureInsertMovies
        )
        let result: Result<NSBatchInsertResult, CoreDataRepositoryError> = try await repository().insert(request)

        switch result {
        case .success:
            XCTFail("Not expecting a success result")
        case .failure:
            XCTAssert(true)
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(data.map { $0.title ?? "" }.sorted(), [], "There should be no inserted values.")
        }
    }

    func testCreateSuccess() async throws {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let newMovies = try movies.map(mapDictToMovie(_:))
        let result: (success: [Movie], failed: [Movie]) = try await repository().create(newMovies)

        XCTAssertEqual(result.success.count, newMovies.count)
        XCTAssertEqual(result.failed.count, 0)

        for movie in result.success {
            try await verify(movie)
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map { $0.title ?? "" }.sorted(),
                ["A", "B", "C", "D", "E"],
                "Inserted titles should match expectation"
            )
        }
    }

    func testReadSuccess() async throws {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let repoMovies = try self.movies
                .map(self.mapDictToRepoMovie(_:))
            try self.repositoryContext().save()
            movies = repoMovies.map(\.asUnmanaged)
        }

        let result: (success: [Movie], failed: [URL]) = try await repository().read(urls: movies.compactMap(\.url))

        XCTAssertEqual(result.success.count, movies.count)
        XCTAssertEqual(result.failed.count, 0)

        XCTAssertEqual(Set(movies), Set(result.success))
    }

    func testUpdateSuccess() async throws {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let _ = try self.movies
                .map(self.mapDictToRepoMovie(_:))
            try self.repositoryContext().save()
        }

        let predicate = NSPredicate(value: true)
        let request = NSBatchUpdateRequest(entityName: try XCTUnwrap(RepoMovie.entity().name))
        request.predicate = predicate
        request.propertiesToUpdate = ["title": "Updated!", "boxOffice": 1]

        let _: Result<NSBatchUpdateResult, CoreDataRepositoryError> = try await repository().update(request)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map { $0.title ?? "" }.sorted(),
                ["Updated!", "Updated!", "Updated!", "Updated!", "Updated!"],
                "Updated titles should match request"
            )
        }
    }

    func testAltUpdateSuccess() async throws {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let repoMovies = try self.movies
                .map(self.mapDictToRepoMovie(_:))
            try self.repositoryContext().save()
            movies = repoMovies.map(\.asUnmanaged)
        }

        var editedMovies = movies
        let newTitles = ["ZA", "ZB", "ZC", "ZD", "ZE"]
        newTitles.enumerated().forEach { index, title in editedMovies[index].title = title }

        let result: (success: [Movie], failed: [Movie]) = try await repository().update(editedMovies)

        XCTAssertEqual(result.success.count, movies.count)
        XCTAssertEqual(result.failed.count, 0)

        XCTAssertEqual(Set(editedMovies), Set(result.success))
    }

    func testDeleteSuccess() async throws {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let _ = try self.movies
                .map(self.mapDictToRepoMovie(_:))
            try self.repositoryContext().save()
        }

        let request =
            NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: try XCTUnwrap(
                RepoMovie
                    .entity().name
            )))

        let _: Result<NSBatchDeleteResult, CoreDataRepositoryError> = try await repository().delete(request)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(data.map { $0.title ?? "" }.sorted(), [], "There should be no remaining values.")
        }
    }

    func testAltDeleteSuccess() async throws {
        let fetchRequest = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let repoMovies = try self.movies
                .map(self.mapDictToRepoMovie(_:))
            try self.repositoryContext().save()
            movies = repoMovies.map(\.asUnmanaged)
        }

        let result: (success: [URL], failed: [URL]) = try await repository().delete(urls: movies.compactMap(\.url))

        XCTAssertEqual(result.success.count, movies.count)
        XCTAssertEqual(result.failed.count, 0)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(data.map { $0.title ?? "" }.sorted(), [], "There should be no remaining values.")
        }
    }
}
