//
//  BatchRepositoryTests.swift
//  
//
//  Created by Andrew Roan on 1/22/21.
//

import XCTest
import CoreData
@testable import CoreDataRepository

class CoreDataXCTestCase: XCTestCase {

    var _viewContext: NSManagedObjectContext?
    var _backgroundContext: NSManagedObjectContext?
    let mainQueue = DispatchQueue.main
    let backgroundQueue = DispatchQueue(label: "background", qos: .userInitiated)

    var viewContext: NSManagedObjectContext { self._viewContext! }
    var backgroundContext: NSManagedObjectContext { self._backgroundContext! }

    override func setUp() {
        let container = CoreDataStack.persistentContainer
        self._viewContext = container.viewContext
        self._viewContext?.automaticallyMergesChangesFromParent = true
        self._backgroundContext = container.newBackgroundContext()
        self._backgroundContext?.automaticallyMergesChangesFromParent = true
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        self._viewContext = nil
        self._backgroundContext = nil
    }
}
