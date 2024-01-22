// Movie.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import CoreDataRepository

struct Movie: Hashable {
    let id: UUID
    var title: String = ""
    var releaseDate: Date
    var boxOffice: Decimal = 0
    var url: URL?
}

extension Movie: UnmanagedModel {
    init(managed: ManagedMovie) throws {
        self.init(
            id: managed.id,
            title: managed.title,
            releaseDate: managed.releaseDate,
            boxOffice: managed.boxOffice as Decimal,
            url: managed.objectID.uriRepresentation()
        )
    }

    var managedIdUrl: URL? {
        get {
            url
        }
        set(newValue) {
            url = newValue
        }
    }

    func asManagedModel(in context: NSManagedObjectContext) throws -> ManagedMovie {
        let object = ManagedMovie(context: context)
        object.id = id
        object.title = title
        object.releaseDate = releaseDate
        object.boxOffice = boxOffice as NSDecimalNumber
        return object
    }

    func updating(managed: ManagedMovie) throws {
        managed.id = id
        managed.title = title
        managed.releaseDate = releaseDate
        managed.boxOffice = NSDecimalNumber(decimal: boxOffice)
    }
}

@objc(ManagedMovie)
final class ManagedMovie: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var releaseDate: Date
    @NSManaged var boxOffice: NSDecimalNumber
}

extension ManagedMovie {
    override class func entity() -> NSEntityDescription {
        entityDescription
    }

    private static let entityDescription: NSEntityDescription = {
        let desc = NSEntityDescription()
        desc.name = "ManagedMovie"
        desc.managedObjectClassName = NSStringFromClass(ManagedMovie.self)
        desc.properties = [
            iDDescription,
            titleDescription,
            releaseDateDescription,
            boxOfficeDescription,
        ]
        desc.uniquenessConstraints = [[iDDescription]]
        return desc
    }()

    private static var iDDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "id"
        desc.type = .uuid
        desc.isOptional = false
        return desc
    }

    private static var titleDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "title"
        desc.type = .string
        desc.isOptional = false
        return desc
    }

    private static var releaseDateDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "releaseDate"
        desc.type = .date
        desc.isOptional = false
        return desc
    }

    private static var boxOfficeDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "boxOffice"
        desc.type = .decimal
        desc.isOptional = false
        return desc
    }
}

extension ManagedMovie {
    static func fetchRequest() -> NSFetchRequest<ManagedMovie> {
        let request = Movie.managedFetchRequest()
        return request
    }
}
