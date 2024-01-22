// CoreDataXCTestCase.swift
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

class CoreDataXCTestCase: XCTestCase {
    var _container: NSPersistentContainer?
    var _repositoryContext: NSManagedObjectContext?
    var _repository: CoreDataRepository?
    let mainQueue = DispatchQueue.main
    let backgroundQueue = DispatchQueue(label: "background", qos: .userInitiated)

    func container() throws -> NSPersistentContainer {
        try XCTUnwrap(_container)
    }

    func repositoryContext() throws -> NSManagedObjectContext {
        try XCTUnwrap(_repositoryContext)
    }

    func repository() throws -> CoreDataRepository {
        try XCTUnwrap(_repository)
    }

    override func setUpWithError() throws {
        let container = CoreDataStack.persistentContainer
        _container = container
        backgroundQueue.sync {
            _repositoryContext = container.newBackgroundContext()
            _repositoryContext?.automaticallyMergesChangesFromParent = true
        }
        _repository = try CoreDataRepository(context: repositoryContext())
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        _container = nil
        _repositoryContext = nil
        _repository = nil
    }

    func verify<T>(_ item: T) async throws where T: UnmanagedModel {
        guard let url = item.managedIdUrl else {
            XCTFail("Failed to verify item in store because it has no URL")
            return
        }

        let context = try repositoryContext()
        let coordinator = try container().persistentStoreCoordinator
        try context.performAndWait {
            guard let objectID = coordinator.managedObjectID(forURIRepresentation: url) else {
                XCTFail("Failed to verify item in store because no NSManagedObjectID found in viewContext from URL.")
                return
            }
            var _object: NSManagedObject?
            do {
                _object = try context.existingObject(with: objectID)
            } catch {
                XCTFail(
                    "Failed to verify item in store because it was not found by its NSManagedObjectID. Error: \(error.localizedDescription)"
                )
                return
            }

            guard let object = _object else {
                XCTFail("Failed to verify item in store because it was not found by its NSManagedObjectID")
                return
            }

            guard let managedItem = object as? T.ManagedModel else {
                XCTFail("Failed to verify item in store because it failed to cast to RepoManaged type.")
                return
            }
            XCTAssertNoDifference(item, try T(managed: managedItem))
        }
    }

    func verify(transactionAuthor: String?, timeStamp: Date) throws {
        let historyRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: timeStamp)
        try repositoryContext().performAndWait {
            let historyResult = try XCTUnwrap(repositoryContext().execute(historyRequest) as? NSPersistentHistoryResult)
            let history = try XCTUnwrap(historyResult.result as? [NSPersistentHistoryTransaction])
            XCTAssertGreaterThan(history.count, 0)
            for historyTransaction in history {
                XCTAssertEqual(historyTransaction.author, transactionAuthor)
            }
        }
    }

    func removeManagedUrl<T>(from item: T) -> T where T: UnmanagedModel {
        var item = item
        item[keyPath: \.managedIdUrl] = nil
        return item
    }

    func removeManagedUrls<T>(from items: some Sequence<T>) -> [T] where T: UnmanagedModel {
        items.map(removeManagedUrl(from:))
    }
}
