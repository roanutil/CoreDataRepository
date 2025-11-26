// CoreDataStack.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData

public enum CoreDataStoreType: String, Hashable, Sendable {
    case binary
    case inMemory
    case sqlite
    /// sqlite but located at /dev/null
    case sqliteEphemeral

    public var persistentStoreType: NSPersistentStore.StoreType {
        switch self {
        case .binary:
            .binary
        case .inMemory:
            .inMemory
        case .sqlite:
            .sqlite
        case .sqliteEphemeral:
            .sqlite
        }
    }

    public var supportsHistoryTracking: Bool {
        switch self {
        case .binary, .inMemory:
            false
        case .sqlite, .sqliteEphemeral:
            true
        }
    }
}

public final class CoreDataStack {
    public let storeName: String
    public let type: CoreDataStoreType
    public let container: NSPersistentContainer

    public func url() -> URL? {
        container.persistentStoreDescriptions.first?.url
    }

    public func destroy() throws {
        if let url = url(), type != .sqliteEphemeral, url.absoluteString != "file:///dev/null" {
            try container.persistentStoreCoordinator.destroyPersistentStore(at: url, type: type.persistentStoreType)
            let directory = url.deletingLastPathComponent()
            let shmPath = Self.storeShmLocation(name: storeName, in: directory)
            let walPath = Self.storeWalLocation(name: storeName, in: directory)
            try FileManager.default.removeItem(at: url)
            try FileManager.default.removeItem(at: shmPath)
            try FileManager.default.removeItem(at: walPath)
        } else {
            try container.persistentStoreCoordinator
                .remove(container.persistentStoreCoordinator.persistentStores.first!)
        }
    }

    public static func persistentContainer(
        storeName: String,
        type: CoreDataStoreType,
        model: NSManagedObjectModel
    ) -> NSPersistentContainer {
        let description: NSPersistentStoreDescription
        let url: URL? = switch type {
        case .binary:
            storeLocation(name: storeName)
        case .sqlite:
            storeLocation(name: storeName)
        case .inMemory:
            nil
        case .sqliteEphemeral:
            nil
        }
        if let url {
            description = NSPersistentStoreDescription(url: url)
        } else {
            description = NSPersistentStoreDescription()
        }

        description.setOption(type.supportsHistoryTracking as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        description.type = type.persistentStoreType.rawValue
        description.shouldAddStoreAsynchronously = false
        let container = NSPersistentContainer(name: storeName, managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }

    public static func xcDataModel(name: String, bundle: Bundle) -> NSManagedObjectModel {
        NSManagedObjectModel(contentsOf: bundle.url(
            forResource: name,
            withExtension: "momd"
        )!)!
    }

    public static let storeDefaultDirectory: URL = NSPersistentContainer.defaultDirectoryURL()

    public static func storeLocation(name: String, in directory: URL = storeDefaultDirectory) -> URL {
        directory.appendingPathComponent("\(name).sqlite")
    }

    public static func storeWalLocation(name: String, in directory: URL = storeDefaultDirectory) -> URL {
        directory.appendingPathComponent("\(name).sqlite-wal")
    }

    public static func storeShmLocation(name: String, in directory: URL = storeDefaultDirectory) -> URL {
        directory.appendingPathComponent("\(name).sqlite-shm")
    }

    public init(storeName: String, type: CoreDataStoreType, container: NSPersistentContainer) {
        self.storeName = storeName
        self.type = type
        self.container = container
    }

    public convenience init(storeName: String, type: CoreDataStoreType, bundle: Bundle) {
        self.init(
            storeName: storeName,
            type: type,
            container: Self.persistentContainer(
                storeName: storeName,
                type: type,
                model: Self.xcDataModel(name: storeName, bundle: bundle)
            )
        )
    }
}
