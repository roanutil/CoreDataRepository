// CoreDataStack.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

public enum CoreDataStack {
    private static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [
            FileCabinet.Managed.entityDescription,
            FileCabinet.Drawer.Managed.entityDescription,
            Document.Managed.entityDescription,
        ]
        return model
    }()

    public static func persistentContainer() -> NSPersistentContainer {
        let desc = NSPersistentStoreDescription()
        desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        desc.type = NSSQLiteStoreType
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
        return container
    }
}
