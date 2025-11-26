// CoreDataStack.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

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
