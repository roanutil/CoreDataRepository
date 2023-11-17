// CoreDataStack.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation
import OSLog

public final class CoreDataStack {
    
    public static let shared = CoreDataStack()
    
    private let logger: Logger
    public let container: NSPersistentContainer

    /// The file URL for the store
    ///
    /// We will only ever use one store.
    public func url() -> URL? {
        container.persistentStoreDescriptions.first?.url
    }

    public func destroy() throws {
        if let url = url() {
            logger.debug("Destroying store at \(url.absoluteString)")
            try container.persistentStoreCoordinator.destroyPersistentStore(at: url, type: NSPersistentStore.StoreType.sqlite)
        } else {
            logger.debug("No URL found for store. Removing store from coordinator.")
            try container.persistentStoreCoordinator
                .remove(container.persistentStoreCoordinator.persistentStores.first!)
        }
    }

    public static func persistentContainer(
        model: NSManagedObjectModel,
        logger: Logger
    ) -> NSPersistentContainer {
        logger.info("Creating container")
        let description: NSPersistentStoreDescription
        logger.info("Container located at \(storeDefaultLocation.absoluteString)")
        description = NSPersistentStoreDescription(url: storeDefaultLocation)

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        let container = NSPersistentContainer(name: "CoreDataModel", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }

    public static let defaultModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [
            FileCabinet.Managed.entityDescription,
            FileCabinet.Drawer.Managed.entityDescription,
            Document.Managed.entityDescription,
        ]
        return model
    }()

    public static let storeDefaultDirectory: URL = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
    ).first!

    public static let storeDefaultLocation: URL = storeDefaultDirectory.appendingPathComponent("repository.sqlite")

    public static let storeWalDefaultLocation: URL = storeDefaultDirectory.appendingPathComponent("repository.sqlite-wal")

    public static let storeShmDefaultLocation: URL = storeDefaultDirectory.appendingPathComponent("repository.sqlite-shm")

    public init() {
        let _logger = Logger(subsystem: "com.CoreDataRepository.RelationshipsExample", category: "CoreDataStack")
        self.logger = _logger
        self.container = Self.persistentContainer(model: Self.defaultModel, logger: _logger)
    }
}
