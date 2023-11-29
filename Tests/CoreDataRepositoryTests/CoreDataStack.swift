// CoreDataStack.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData

class CoreDataStack: NSObject {
    private static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [ManagedMovie.entity()]
        return model
    }()

    static var persistentContainer: NSPersistentContainer {
        let desc = NSPersistentStoreDescription()
        desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        desc.type = NSSQLiteStoreType // NSInMemoryStoreType
        desc.shouldAddStoreAsynchronously = false
        let model = Self.model
        let container = NSPersistentContainer(name: "Model", managedObjectModel: model)
        container.persistentStoreDescriptions = [desc]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        print("Store located at: \(desc.url!)")
        return container
    }
}
