// BatchRepositoryTests.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import CoreDataRepository
import CustomDump
import XCTest

final class BatchRepositoryTests: CoreDataXCTestCase {
    let movies: [[String: Any]] = [
        ["id": UUID(uniform: "A"), "title": "A", "releaseDate": Date(timeIntervalSinceReferenceDate: 0)],
        ["id": UUID(uniform: "B"), "title": "B", "releaseDate": Date(timeIntervalSinceReferenceDate: 1)],
        ["id": UUID(uniform: "C"), "title": "C", "releaseDate": Date(timeIntervalSinceReferenceDate: 2)],
        ["id": UUID(uniform: "D"), "title": "D", "releaseDate": Date(timeIntervalSinceReferenceDate: 3)],
        ["id": UUID(uniform: "E"), "title": "E", "releaseDate": Date(timeIntervalSinceReferenceDate: 4)],
    ]
    let failureInsertMovies: [[String: Any]] = [
        ["id": "A", "title": 1, "releaseDate": "A"],
        ["id": "B", "title": 2, "releaseDate": "B"],
        ["id": "C", "title": 3, "releaseDate": "C"],
        ["id": "D", "title": 4, "releaseDate": "D"],
        ["id": "E", "title": 5, "releaseDate": "E"],
    ]
    let failureCreateMovies: [[String: Any]] = [
        ["id": UUID(uniform: "A"), "title": "A", "releaseDate": Date()],
        ["id": UUID(uniform: "A"), "title": "B", "releaseDate": Date()],
        ["id": UUID(uniform: "A"), "title": "C", "releaseDate": Date()],
        ["id": UUID(uniform: "A"), "title": "D", "releaseDate": Date()],
        ["id": UUID(uniform: "A"), "title": "E", "releaseDate": Date()],
    ]

    func mapDictToManagedMovie(_ dict: [String: Any]) throws -> ManagedMovie {
        try mapDictToMovie(dict)
            .asManagedModel(in: repositoryContext())
    }

    func mapDictToMovie(_ dict: [String: Any]) throws -> Movie {
        let id = try XCTUnwrap(dict["id"] as? UUID)
        let title = try XCTUnwrap(dict["title"] as? String)
        let releaseDate = try XCTUnwrap(dict["releaseDate"] as? Date)
        return Movie(id: id, title: title, releaseDate: releaseDate)
    }

    func testInsertSuccess() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let request = try NSBatchInsertRequest(entityName: XCTUnwrap(ManagedMovie.entity().name), objects: movies)
        let result: Result<NSBatchInsertResult, CoreDataError> = try await repository()
            .insert(request, transactionAuthor: transactionAuthor)

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

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testInsertFailure() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let request = try NSBatchInsertRequest(
            entityName: XCTUnwrap(ManagedMovie.entity().name),
            objects: failureInsertMovies
        )
        let result: Result<NSBatchInsertResult, CoreDataError> = try await repository().insert(request)

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
        let fetchRequest = Movie.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let newMovies = try movies.map(mapDictToMovie(_:))
        let result: (success: [Movie], failed: [CoreDataBatchError<Movie>]) = try await repository()
            .create(newMovies, transactionAuthor: transactionAuthor)

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

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreateAtomicallySuccess() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let newMovies = try movies.map(mapDictToMovie(_:))
        let createdMovies: [Movie]
        switch try await repository()
            .createAtomically(newMovies, transactionAuthor: transactionAuthor)
        {
        case let .success(_createdMovies):
            createdMovies = _createdMovies
        case let .failure(error):
            XCTFail("Not expecting failure: \(error.localizedDescription)")
            return
        }

        XCTAssertEqual(createdMovies.count, newMovies.count)

        for movie in createdMovies {
            try await verify(movie)
        }

        let createdMoviesForEquality = createdMovies.map { movie in
            var movie = movie
            XCTAssertNotNil(movie.url)
            movie.url = nil
            return movie
        }

        XCTAssertNoDifference(createdMoviesForEquality, newMovies)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map { $0.title ?? "" }.sorted(),
                ["A", "B", "C", "D", "E"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testReadSuccess() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let managedMovies = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
            movies = try managedMovies.map(Movie.init(managed:))
        }

        let result = try await repository().read(urls: movies.compactMap(\.url), as: Movie.self)

        XCTAssertEqual(result.success.count, movies.count)
        XCTAssertEqual(result.failed.count, 0)

        XCTAssertEqual(Set(movies), Set(result.success))
    }

    func testReadAtomicallySuccess() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let managedMovies = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
            movies = try managedMovies.map(Movie.init(managed:))
        }

        let readMovies: [Movie]
        switch try await repository().readAtomically(urls: movies.compactMap(\.url), as: Movie.self) {
        case let .success(_readMovies):
            readMovies = _readMovies
        case let .failure(error):
            XCTFail("Not expecting failure: \(error.localizedDescription)")
            return
        }

        XCTAssertEqual(readMovies.count, movies.count)

        XCTAssertNoDifference(readMovies, movies)
    }

    func testUpdateSuccess() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let _ = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
        }

        let predicate = NSPredicate(value: true)
        let request = try NSBatchUpdateRequest(entityName: XCTUnwrap(ManagedMovie.entity().name))
        request.predicate = predicate
        request.propertiesToUpdate = ["title": "Updated!", "boxOffice": 1]

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let _: Result<NSBatchUpdateResult, CoreDataError> = try await repository()
            .update(request, transactionAuthor: transactionAuthor)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map { $0.title ?? "" }.sorted(),
                ["Updated!", "Updated!", "Updated!", "Updated!", "Updated!"],
                "Updated titles should match request"
            )
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testAltUpdateSuccess() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let managedMovies = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
            movies = try managedMovies.map(Movie.init(managed:))
        }

        var editedMovies = movies
        let newTitles = ["ZA", "ZB", "ZC", "ZD", "ZE"]
        newTitles.enumerated().forEach { index, title in editedMovies[index].title = title }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let result: (success: [Movie], failed: [CoreDataBatchError<Movie>]) = try await repository()
            .update(editedMovies, transactionAuthor: transactionAuthor)

        XCTAssertEqual(result.success.count, movies.count)
        XCTAssertEqual(result.failed.count, 0)

        XCTAssertNoDifference(Set(editedMovies), Set(result.success))

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testAltUpdateAtomicallySuccess() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let managedMovies = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
            movies = try managedMovies.map(Movie.init(managed:))
        }

        var editedMovies = movies
        let newTitles = ["ZA", "ZB", "ZC", "ZD", "ZE"]
        newTitles.enumerated().forEach { index, title in editedMovies[index].title = title }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let updatedMovies: [Movie]
        switch try await repository()
            .updateAtomically(editedMovies, transactionAuthor: transactionAuthor)
        {
        case let .success(_updatedMovies):
            updatedMovies = _updatedMovies
        case let .failure(error):
            XCTFail("Not expecting failure: \(error.localizedDescription)")
            return
        }

        XCTAssertEqual(updatedMovies.count, movies.count)

        XCTAssertNoDifference(updatedMovies, editedMovies)

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testDeleteSuccess() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let _ = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
        }

        let request =
            try NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: XCTUnwrap(
                ManagedMovie
                    .entity().name
            )))

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let _: Result<NSBatchDeleteResult, CoreDataError> = try await repository()
            .delete(request, transactionAuthor: transactionAuthor)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(data.map { $0.title ?? "" }.sorted(), [], "There should be no remaining values.")
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testAltDeleteSuccess() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let managedMovies = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
            movies = try managedMovies.map(Movie.init(managed:))
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        let result: (success: [URL], failed: [CoreDataBatchError<URL>]) = try await repository()
            .delete(urls: movies.compactMap(\.url), transactionAuthor: transactionAuthor)

        XCTAssertEqual(result.success.count, movies.count)
        XCTAssertEqual(result.failed.count, 0)

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(data.map { $0.title ?? "" }.sorted(), [], "There should be no remaining values.")
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testAltDeleteAtomicallySuccess() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let managedMovies = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
            movies = try managedMovies.map(Movie.init(managed:))
        }

        let historyTimeStamp = Date()
        let transactionAuthor: String = #function

        switch try await repository()
            .deleteAtomically(urls: movies.compactMap(\.url), transactionAuthor: transactionAuthor)
        {
        case .success:
            break
        case let .failure(error):
            XCTFail("Not expecting failure: \(error.localizedDescription)")
            return
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(data.map { $0.title ?? "" }.sorted(), [], "There should be no remaining values.")
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }
}
