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
        model.entities = [MovieDescription]
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
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }

    // Manually build model entities. Having trouble with the package loading the model from bundle.
    private static var MovieDescription: NSEntityDescription {
        let desc = NSEntityDescription()
        desc.name = "RepoMovie"
        desc.managedObjectClassName = NSStringFromClass(RepoMovie.self)
        desc.properties = [
            movieIDDescription,
            movieTitleDescription,
            movieReleaseDateDescription,
            movieBoxOfficeDescription,
        ]
        desc.uniquenessConstraints = [[movieIDDescription]]
        return desc
    }

    private static var movieIDDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "id"
        desc.attributeType = .UUIDAttributeType
        return desc
    }

    private static var movieTitleDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "title"
        desc.attributeType = .stringAttributeType
        desc.defaultValue = ""
        return desc
    }

    private static var movieReleaseDateDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "releaseDate"
        desc.attributeType = .dateAttributeType
        return desc
    }

    private static var movieBoxOfficeDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "boxOffice"
        desc.attributeType = .decimalAttributeType
        desc.defaultValue = 0
        return desc
    }
}
