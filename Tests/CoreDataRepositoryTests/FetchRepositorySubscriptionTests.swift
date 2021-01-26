//
//  File.swift
//  
//
//  Created by Andrew Roan on 1/26/21.
//

import CoreData
import Combine
import XCTest
@testable import CoreDataRepository

extension FetchRepositoryTests {
    func testFetchSubscriptionSuccess() {
        let firstExp = expectation(description: "Fetch movies from CoreData")
        let secondExp = expectation(description: "Fetch movies again after CoreData context is updated")
        let finalExp = expectation(description: "Finish fetching movies after canceled.")
        var resultCount = 0
        let subscription = FetchRepository.Subscription<Movie>(id: UUID(), request: self.fetchRequest, context: self.backgroundContext)
        _ = subscription.subject.subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    finalExp.fulfill()
                default:
                    XCTFail("Not expecting failure")
                }
        }, receiveValue: { value in
            resultCount += 1
            switch resultCount {
            case 1:
                assert(value.items.count == 5, "Result items count should match expectation")
                assert(value.items == self.expectedMovies, "Result items should match expectations")
                firstExp.fulfill()
            case 2:
                assert(value.items.count == 4, "Result items count should match expectation")
                assert(value.items == Array(self.expectedMovies[0...3]), "Result items should match expectations")
                secondExp.fulfill()
            default:
                break
            }
            
        })
        subscription.manualFetch()
        wait(for: [firstExp], timeout: 5)
        let crudRepo = CRUDRepository(context: self.backgroundContext)
        let _: AnyPublisher<CRUDRepository.Success<Movie>, CRUDRepository.Failure<Movie>> = crudRepo.delete(expectedMovies.last!.objectID!)
        wait(for: [secondExp], timeout: 5)
        subscription.cancel()
        wait(for: [finalExp], timeout: 5)
    }
}
