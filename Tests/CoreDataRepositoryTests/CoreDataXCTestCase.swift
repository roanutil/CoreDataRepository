// CoreDataXCTestCase.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2021 Andrew Roan

import CoreData
@testable import CoreDataRepository
import XCTest

class CoreDataXCTestCase: XCTestCase {
    var _viewContext: NSManagedObjectContext?
    var _backgroundContext: NSManagedObjectContext?
    let mainQueue = DispatchQueue.main
    let backgroundQueue = DispatchQueue(label: "background", qos: .userInitiated)

    var viewContext: NSManagedObjectContext { _viewContext! }
    var backgroundContext: NSManagedObjectContext { self._backgroundContext! }

    override func setUp() {
        let container = CoreDataStack.persistentContainer
        _viewContext = container.viewContext
        _viewContext?.automaticallyMergesChangesFromParent = true
        _backgroundContext = container.newBackgroundContext()
        _backgroundContext?.automaticallyMergesChangesFromParent = true
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        _viewContext = nil
        _backgroundContext = nil
    }
}
