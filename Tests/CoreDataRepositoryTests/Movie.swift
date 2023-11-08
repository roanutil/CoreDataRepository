// Movie.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

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
    init(managed: RepoMovie) throws {
        self.init(
            id: managed.id!,
            title: managed.title!,
            releaseDate: managed.releaseDate!,
            boxOffice: managed.boxOffice! as Decimal,
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

    func asManagedModel(in context: NSManagedObjectContext) throws -> RepoMovie {
        let object = RepoMovie(context: context)
        object.id = id
        object.title = title
        object.releaseDate = releaseDate
        object.boxOffice = boxOffice as NSDecimalNumber
        return object
    }

    func updating(managed: RepoMovie) throws {
        managed.id = id
        managed.title = title
        managed.releaseDate = releaseDate
        managed.boxOffice = NSDecimalNumber(decimal: boxOffice)
    }
}

@objc(RepoMovie)
final class RepoMovie: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var releaseDate: Date?
    @NSManaged var boxOffice: NSDecimalNumber?
}

extension RepoMovie {
    static func fetchRequest() -> NSFetchRequest<RepoMovie> {
        let request = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        return request
    }
}
