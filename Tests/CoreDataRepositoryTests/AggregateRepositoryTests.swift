//
//  AggregateRepositoryTests.swift
//  
//
//  Created by Andrew Roan on 1/23/21.
//

import CoreData
import Combine
import XCTest
@testable import CoreDataRepository

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CoreDataSourceTests.allTests),
    ]
}
#endif

final class AggregateRepositoryTests: CoreDataXCTestCase {

    static var allTests = [
        ("testCountSuccess", testCountSuccess),
        ("testSumSuccess", testSumSuccess),
        ("testAverageSuccess", testAverageSuccess),
        ("testMinSuccess", testMinSuccess),
        ("testMaxSuccess", testMaxSuccess)
    ]

    typealias Success = AggregateRepository.Success
    typealias Failure = AggregateRepository.Failure

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
    var _repository: AggregateRepository?
    var repository: AggregateRepository { _repository! }

    override func setUp() {
        super.setUp()
        self._repository = AggregateRepository(context: self.backgroundContext)
        objectIDs = movies.map { $0.asRepoManaged(in: self.viewContext).objectID }
        try! viewContext.save()
    }

    override func tearDown() {
        super.tearDown()
        self._repository = nil
        self.objectIDs = []
    }

    func testCountSuccess() {
        let exp = expectation(description: "Get count of movies from CoreData")
        let result: AnyPublisher<Success<Int>, Failure> = repository.count(predicate: NSPredicate(value: true), entityDesc: RepoMovie.entity())
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    exp.fulfill()
                default:
                    XCTFail("Not expecting failure")
                }
            }, receiveValue: { value in
                assert(value.result.first!.values.first! == 5, "Result value (count) should equal number of movies.")
            })
        wait(for: [exp], timeout: 5)
    }

    func testSumSuccess() {
        let exp = expectation(description: "Get sum of CoreData Movies boxOffice")
        let result: AnyPublisher<Success<Decimal>, Failure> = repository.sum(predicate: NSPredicate(value: true), entityDesc: RepoMovie.entity(), attributeDesc: RepoMovie.entity().attributesByName.values.first(where: { $0.name == "boxOffice" })!)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    exp.fulfill()
                default:
                    XCTFail("Not expecting failure")
                }
            }, receiveValue: { value in
                assert(value.result.first!.values.first! == 150, "Result value (sum) should equal sum of movies box office.")
            })
        wait(for: [exp], timeout: 5)
    }

    func testAverageSuccess() {
        let exp = expectation(description: "Get average of CoreData Movies boxOffice")
        let result: AnyPublisher<Success<Decimal>, Failure> = repository.average(predicate: NSPredicate(value: true), entityDesc: RepoMovie.entity(), attributeDesc: RepoMovie.entity().attributesByName.values.first(where: { $0.name == "boxOffice" })!)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    exp.fulfill()
                default:
                    XCTFail("Not expecting failure")
                }
            }, receiveValue: { value in
                assert(value.result.first!.values.first! == 30, "Result value should equal average of movies box office.")
            })
        wait(for: [exp], timeout: 5)
    }

    func testMinSuccess() {
        let exp = expectation(description: "Get average of CoreData Movies boxOffice")
        let result: AnyPublisher<Success<Decimal>, Failure> = repository.min(predicate: NSPredicate(value: true), entityDesc: RepoMovie.entity(), attributeDesc: RepoMovie.entity().attributesByName.values.first(where: { $0.name == "boxOffice" })!)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    exp.fulfill()
                default:
                    XCTFail("Not expecting failure")
                }
            }, receiveValue: { value in
                assert(value.result.first!.values.first! == 10, "Result value should equal average of movies box office.")
            })
        wait(for: [exp], timeout: 5)
    }

    func testMaxSuccess() {
        let exp = expectation(description: "Get average of CoreData Movies boxOffice")
        let result: AnyPublisher<Success<Decimal>, Failure> = repository.max(predicate: NSPredicate(value: true), entityDesc: RepoMovie.entity(), attributeDesc: RepoMovie.entity().attributesByName.values.first(where: { $0.name == "boxOffice" })!)
        _ = result.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    exp.fulfill()
                default:
                    XCTFail("Not expecting failure")
                }
            }, receiveValue: { value in
                assert(value.result.first!.values.first! == 50, "Result value should equal average of movies box office.")
            })
        wait(for: [exp], timeout: 5)
    }
}
