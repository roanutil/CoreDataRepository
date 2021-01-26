//
//  CoreDataStack.swift
//  
//
//  Created by Andrew Roan on 1/22/21.
//

import CoreData

class CoreDataStack: NSObject {
    private static let model: NSManagedObjectModel = {
        guard let modelURL = Bundle.module.url(forResource: "Model", withExtension: "momd") else {
            fatalError("Failed to create bundle URL for CoreData model.")
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to init CoreData model from URL.")
       }
        return model
    }()

    static var persistentContainer: NSPersistentContainer {
        let desc = NSPersistentStoreDescription()
        desc.type = NSSQLiteStoreType//NSInMemoryStoreType
        desc.shouldAddStoreAsynchronously = false
        let model = Self.model
        let container = NSPersistentContainer(name: "Model", managedObjectModel: model)
        container.persistentStoreDescriptions = [desc]
        container.loadPersistentStores { description, error in
            //precondition( description.type == NSInMemoryStoreType )
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }
}
