// CoreDataXCTestCase.swift
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

class CoreDataXCTestCase: XCTestCase {
    var cancellables: Set<AnyCancellable> = []
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
        _repository = CoreDataRepository(context: try repositoryContext())
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        _container = nil
        _repositoryContext = nil
        _repository = nil
        cancellables.forEach { $0.cancel() }
    }

    func verify<T>(_ item: T) async throws where T: UnmanagedModel {
        guard let url = item.managedRepoUrl else {
            XCTFail("Failed to verify item in store because it has no URL")
            return
        }

        let context = try repositoryContext()
        let coordinator = try container().persistentStoreCoordinator
        context.performAndWait {
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

            guard let managedItem = object as? T.RepoManaged else {
                XCTFail("Failed to verify item in store because it failed to cast to RepoManaged type.")
                return
            }
            XCTAssertNoDifference(item, managedItem.asUnmanaged)
        }
    }
}
