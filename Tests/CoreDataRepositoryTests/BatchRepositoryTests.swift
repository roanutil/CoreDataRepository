// BatchRepositoryTests.swift
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

final class BatchRepositoryTests: CoreDataXCTestCase {
    let movies: [[String: Any]] = [
        [
            "id": UUID(uniform: "A"),
            "title": "A",
            "releaseDate": Date(timeIntervalSinceReferenceDate: 0),
            "boxOffice": Decimal(exactly: 0)!,
        ],
        [
            "id": UUID(uniform: "B"),
            "title": "B",
            "releaseDate": Date(timeIntervalSinceReferenceDate: 1),
            "boxOffice": Decimal(exactly: 1)!,
        ],
        [
            "id": UUID(uniform: "C"),
            "title": "C",
            "releaseDate": Date(timeIntervalSinceReferenceDate: 2),
            "boxOffice": Decimal(exactly: 2)!,
        ],
        [
            "id": UUID(uniform: "D"),
            "title": "D",
            "releaseDate": Date(timeIntervalSinceReferenceDate: 3),
            "boxOffice": Decimal(exactly: 3)!,
        ],
        [
            "id": UUID(uniform: "E"),
            "title": "E",
            "releaseDate": Date(timeIntervalSinceReferenceDate: 4),
            "boxOffice": Decimal(exactly: 4)!,
        ],
    ]
    let failureInsertMovies: [[String: Any]] = [
        ["id": "A", "title": 1, "releaseDate": "A", "boxOffice": Decimal(exactly: 0)!],
        ["id": "B", "title": 2, "releaseDate": "B", "boxOffice": Decimal(exactly: 1)!],
        ["id": "C", "title": 3, "releaseDate": "C", "boxOffice": Decimal(exactly: 2)!],
        ["id": "D", "title": 4, "releaseDate": "D", "boxOffice": Decimal(exactly: 3)!],
        ["id": "E", "title": 5, "releaseDate": "E", "boxOffice": Decimal(exactly: 4)!],
    ]
    let failureCreateMovies: [[String: Any]] = [
        ["id": UUID(uniform: "A"), "title": "A", "releaseDate": Date(), "boxOffice": Decimal(exactly: 0)!],
        ["id": UUID(uniform: "A"), "title": "B", "releaseDate": Date(), "boxOffice": Decimal(exactly: 1)!],
        ["id": UUID(uniform: "A"), "title": "C", "releaseDate": Date(), "boxOffice": Decimal(exactly: 2)!],
        ["id": UUID(uniform: "A"), "title": "D", "releaseDate": Date(), "boxOffice": Decimal(exactly: 3)!],
        ["id": UUID(uniform: "A"), "title": "E", "releaseDate": Date(), "boxOffice": Decimal(exactly: 4)!],
    ]

    func mapDictToManagedMovie(_ dict: [String: Any]) throws -> ManagedMovie {
        try mapDictToMovie(dict)
            .asManagedModel(in: repositoryContext())
    }

    func mapDictToMovie(_ dict: [String: Any]) throws -> Movie {
        let id = try XCTUnwrap(dict["id"] as? UUID)
        let title = try XCTUnwrap(dict["title"] as? String)
        let releaseDate = try XCTUnwrap(dict["releaseDate"] as? Date)
        let boxOffice = try XCTUnwrap(dict["boxOffice"] as? Decimal)
        return Movie(id: id, title: title, releaseDate: releaseDate, boxOffice: boxOffice)
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
            break
        case let .failure(error):
            XCTFail("Not expecting a failure result: \(error.localizedDescription)")
        }

        try await repositoryContext().perform {
            let data = try self.repositoryContext().fetch(fetchRequest)
            XCTAssertEqual(
                data.map(\.title).sorted(),
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
            XCTAssertEqual(data.map(\.title).sorted(), [], "There should be no inserted values.")
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
                data.map(\.title).sorted(),
                ["A", "B", "C", "D", "E"],
                "Inserted titles should match expectation"
            )
        }

        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testCreateFailure() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")
            _ = try [self.movies[1], self.movies[3]]
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
        }

        let newMovies = try movies.map(mapDictToMovie(_:))
        let result: (success: [Movie], failed: [CoreDataBatchError<Movie>]) = try await repository()
            .create(newMovies, transactionAuthor: #function)

        XCTAssertEqual(result.success.count, 3)
        XCTAssertEqual(result.failed.count, 2)
        for failure in result.failed {
            print(failure.localizedDescription)
        }
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
                data.map(\.title).sorted(),
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

    func testReadFailure() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let managedMovies = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
            movies = try managedMovies.map(Movie.init(managed:))
            try self.repositoryContext().delete(managedMovies[1])
            try self.repositoryContext().delete(managedMovies[3])
            try self.repositoryContext().save()
        }

        try await verify(movies[0])
        try await verify(movies[2])
        try await verify(movies[4])

        let expectedMovies = try [self.movies[0], self.movies[2], self.movies[4]].map(mapDictToMovie(_:))
        let _result = try await repository().read(urls: movies.compactMap(\.url), as: Movie.self)
        let result = (success: removeManagedUrls(from: _result.success), failed: _result.failed)

        XCTAssertEqual(result.success.count, 3)
        XCTAssertEqual(result.failed.count, 2)

        XCTAssertEqual(
            expectedMovies.sorted(using: KeyPathComparator(\.id.uuidString)),
            result.success.sorted(using: KeyPathComparator(\.id.uuidString))
        )
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
                data.map(\.title).sorted(),
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

    func testAltUpdateFailure() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let managedMovies = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
            try self.repositoryContext().obtainPermanentIDs(for: managedMovies)
            movies = try managedMovies.map(Movie.init(managed:))
            try self.repositoryContext().delete(managedMovies[1])
            try self.repositoryContext().delete(managedMovies[3])
            try self.repositoryContext().save()
        }

        try await verify(movies[0])
        try await verify(movies[2])
        try await verify(movies[4])

        var editedMovies = movies
        let newTitles = ["ZA", "ZB", "ZC", "ZD", "ZE"]
        newTitles.enumerated().forEach { index, title in editedMovies[index].title = title }

        let result = try await repository().update(editedMovies)

        XCTAssertEqual(result.success.count, 3)
        XCTAssertEqual(result.failed.count, 2)

        XCTAssertEqual(
            [editedMovies[0], editedMovies[2], editedMovies[4]].sorted(using: KeyPathComparator(\.id.uuidString)),
            result.success.sorted(using: KeyPathComparator(\.id.uuidString))
        )
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
            XCTAssertEqual(data.map(\.title).sorted(), [], "There should be no remaining values.")
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
            XCTAssertEqual(data.map(\.title).sorted(), [], "There should be no remaining values.")
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }

    func testAltDeleteFailure() async throws {
        let fetchRequest = Movie.managedFetchRequest()
        var movies = [Movie]()
        try await repositoryContext().perform {
            let count = try self.repositoryContext().count(for: fetchRequest)
            XCTAssertEqual(count, 0, "Count of objects in CoreData should be zero at the start of each test.")

            let managedMovies = try self.movies
                .map(self.mapDictToManagedMovie(_:))
            try self.repositoryContext().save()
            movies = try managedMovies.map(Movie.init(managed:))
            try self.repositoryContext().delete(managedMovies[1])
            try self.repositoryContext().delete(managedMovies[3])
            try self.repositoryContext().save()
        }

        try await verify(movies[0])
        try await verify(movies[2])
        try await verify(movies[4])

        let urlsToDelete = try movies.map { try XCTUnwrap($0.url) }

        let result = try await repository().delete(urls: urlsToDelete)

        XCTAssertEqual(result.success.count, 3)
        XCTAssertEqual(result.failed.count, 2)

        XCTAssertEqual(
            [urlsToDelete[0], urlsToDelete[2], urlsToDelete[4]].sorted(using: KeyPathComparator(\.absoluteString)),
            result.success.sorted(using: KeyPathComparator(\.absoluteString))
        )
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
            XCTAssertEqual(data.map(\.title).sorted(), [], "There should be no remaining values.")
        }
        try verify(transactionAuthor: transactionAuthor, timeStamp: historyTimeStamp)
    }
}
