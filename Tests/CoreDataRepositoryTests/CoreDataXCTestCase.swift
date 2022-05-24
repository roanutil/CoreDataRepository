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
    var _viewContext: NSManagedObjectContext?
    let mainQueue = DispatchQueue.main
    let backgroundQueue = DispatchQueue(label: "background", qos: .userInitiated)

    var viewContext: NSManagedObjectContext { _viewContext! }

    override func setUpWithError() throws {
        let container = CoreDataStack.persistentContainer
        _viewContext = container.viewContext
        _viewContext?.automaticallyMergesChangesFromParent = true
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        _viewContext = nil
        cancellables.forEach { $0.cancel() }
    }
}
