// AggregateRepositoryTests.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CoreData
import CoreDataRepository
import XCTest

final class AggregateRepositoryTests: CoreDataXCTestCase {
    let fetchRequest: NSFetchRequest<RepoMovie> = {
        let request = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RepoMovie.title, ascending: true)]
        return request
    }()

    let movies = [
        Movie(id: UUID(), title: "A", releaseDate: Date(), boxOffice: 10),
        Movie(id: UUID(), title: "B", releaseDate: Date(), boxOffice: 20),
        Movie(id: UUID(), title: "C", releaseDate: Date(), boxOffice: 30),
        Movie(id: UUID(), title: "D", releaseDate: Date(), boxOffice: 40),
        Movie(id: UUID(), title: "E", releaseDate: Date(), boxOffice: 50),
    ]
    var objectIDs = [NSManagedObjectID]()

    override func setUpWithError() throws {
        try super.setUpWithError()
        try repositoryContext().performAndWait {
            objectIDs = try movies.map { try $0.asRepoManaged(in: self.repositoryContext()).objectID }
            try repositoryContext().save()
        }
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        objectIDs = []
    }

    func testCountSuccess() async throws {
        let result: Result<[[String: Int]], CoreDataRepositoryError> = try await repository()
            .count(predicate: NSPredicate(value: true), entityDesc: RepoMovie.entity())
        switch result {
        case let .success(values):
            let firstValue = try XCTUnwrap(values.first?.values.first)
            XCTAssertEqual(firstValue, 5, "Result value (count) should equal number of movies.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testSumSuccess() async throws {
        let result: Result<[[String: Decimal]], CoreDataRepositoryError> = try await repository().sum(
            predicate: NSPredicate(value: true),
            entityDesc: RepoMovie.entity(),
            attributeDesc: XCTUnwrap(
                RepoMovie.entity().attributesByName.values
                    .first(where: { $0.name == "boxOffice" })
            )
        )
        switch result {
        case let .success(values):
            let firstValue = try XCTUnwrap(values.first?.values.first)
            XCTAssertEqual(firstValue, 150, "Result value (sum) should equal number of movies.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testAverageSuccess() async throws {
        let result: Result<[[String: Decimal]], CoreDataRepositoryError> = try await repository().average(
            predicate: NSPredicate(value: true),
            entityDesc: RepoMovie.entity(),
            attributeDesc: XCTUnwrap(
                RepoMovie.entity().attributesByName.values
                    .first(where: { $0.name == "boxOffice" })
            )
        )
        switch result {
        case let .success(values):
            let firstValue = try XCTUnwrap(values.first?.values.first)
            XCTAssertEqual(
                firstValue,
                30,
                "Result value should equal average of movies box office."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testMinSuccess() async throws {
        let result: Result<[[String: Decimal]], CoreDataRepositoryError> = try await repository().min(
            predicate: NSPredicate(value: true),
            entityDesc: RepoMovie.entity(),
            attributeDesc: XCTUnwrap(
                RepoMovie.entity().attributesByName.values
                    .first(where: { $0.name == "boxOffice" })
            )
        )
        switch result {
        case let .success(values):
            let firstValue = try XCTUnwrap(values.first?.values.first)
            XCTAssertEqual(
                firstValue,
                10,
                "Result value should equal min of movies box office."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testMaxSuccess() async throws {
        let result: Result<[[String: Decimal]], CoreDataRepositoryError> = try await repository().max(
            predicate: NSPredicate(value: true),
            entityDesc: RepoMovie.entity(),
            attributeDesc: XCTUnwrap(
                RepoMovie.entity().attributesByName.values
                    .first(where: { $0.name == "boxOffice" })
            )
        )
        switch result {
        case let .success(values):
            let firstValue = try XCTUnwrap(values.first?.values.first)
            XCTAssertEqual(
                firstValue,
                50,
                "Result value should equal max of movies box office."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testCountWithPredicate() async throws {
        let result: Result<[[String: Int]], CoreDataRepositoryError> = try await repository()
            .count(predicate: NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \RepoMovie.title),
                rightExpression: NSExpression(forConstantValue: "A"),
                modifier: .direct,
                type: .notEqualTo
            ), entityDesc: RepoMovie.entity())
        switch result {
        case let .success(values):
            let firstValue = try XCTUnwrap(values.first?.values.first)
            XCTAssertEqual(firstValue, 4, "Result value (count) should equal number of movies not titled 'A'.")
        case .failure:
            XCTFail("Not expecting failure")
        }
    }

    func testSumWithPredicate() async throws {
        let result: Result<[[String: Decimal]], CoreDataRepositoryError> = try await repository().sum(
            predicate: NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: \RepoMovie.title),
                rightExpression: NSExpression(forConstantValue: "A"),
                modifier: .direct,
                type: .notEqualTo
            ),
            entityDesc: RepoMovie.entity(),
            attributeDesc: XCTUnwrap(
                RepoMovie.entity().attributesByName.values
                    .first(where: { $0.name == "boxOffice" })
            )
        )
        switch result {
        case let .success(values):
            let firstValue = try XCTUnwrap(values.first?.values.first)
            XCTAssertEqual(
                firstValue,
                140,
                "Result value should equal sum of movies box office that are not titled 'A'."
            )
        case .failure:
            XCTFail("Not expecting failure")
        }
    }
}
