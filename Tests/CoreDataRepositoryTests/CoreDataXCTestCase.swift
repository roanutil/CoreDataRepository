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
import XCTest

class CoreDataXCTestCase: XCTestCase {
    var cancellables: Set<AnyCancellable> = []
    var _container: NSPersistentContainer?
    var _viewContext: NSManagedObjectContext?
    var _repositoryContext: NSManagedObjectContext?
    var _repository: CoreDataRepository?
    let mainQueue = DispatchQueue.main
    let backgroundQueue = DispatchQueue(label: "background", qos: .userInitiated)

    func container() throws -> NSPersistentContainer {
        try XCTUnwrap(_container)
    }

    func viewContext() throws -> NSManagedObjectContext {
        try XCTUnwrap(_viewContext)
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
        _viewContext = container.viewContext
        _viewContext?.automaticallyMergesChangesFromParent = true
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
        _viewContext = nil
        _repositoryContext = nil
        _repository = nil
        cancellables.forEach { $0.cancel() }
    }
}
