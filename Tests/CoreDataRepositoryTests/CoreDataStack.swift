//
//  CoreDataStack.swift
//  
//
//  Created by Andrew Roan on 1/22/21.
//

import CoreData

class CoreDataStack: NSObject {
    private static let model: NSManagedObjectModel = {
        // Manually build model entities. Having trouble with the package loading the model from bundle.
        /*guard let modelURL = Bundle.module.url(forResource: "Model", withExtension: "momd") else {
            fatalError("Failed to create bundle URL for CoreData model.")
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to init CoreData model from URL.")
       }*/
        let model = NSManagedObjectModel()
        model.entities = [MovieDescription]
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

    // Manually build model entities. Having trouble with the package loading the model from bundle.
    static private var MovieDescription: NSEntityDescription {
        let desc = NSEntityDescription()
        desc.name = "RepoMovie"
        desc.managedObjectClassName = NSStringFromClass(RepoMovie.self)
        desc.properties = [
            movieIDDescription,
            movieTitleDescription,
            movieReleaseDateDescription,
            movieBoxOfficeDescription
        ]
        desc.uniquenessConstraints = [["id"]]
        return desc
    }

    static private var movieIDDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "id"
        desc.attributeType = .UUIDAttributeType
        return desc
    }

    static private var movieTitleDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "title"
        desc.attributeType = .stringAttributeType
        desc.defaultValue = ""
        return desc
    }

    static private var movieReleaseDateDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "releaseDate"
        desc.attributeType = .dateAttributeType
        return desc
    }

    static private var movieBoxOfficeDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "boxOffice"
        desc.attributeType = .decimalAttributeType
        desc.defaultValue = 0
        return desc
    }
}
