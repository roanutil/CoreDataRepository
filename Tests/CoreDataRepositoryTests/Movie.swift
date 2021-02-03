//
//  Movie.swift
//  
//
//  Created by Andrew Roan on 1/22/21.
//

import CoreData
@testable import CoreDataRepository

public struct Movie {
    public let id: UUID
    public var title: String = ""
    public var releaseDate: Date
    public var boxOffice: Decimal = 0
    public var objectID: NSManagedObjectID?
}

extension Movie: UnmanagedModel {
    public func asRepoManaged(in context: NSManagedObjectContext) -> RepoMovie {
        let object = RepoMovie(context: context)
        object.id = id
        object.title = title
        object.releaseDate = releaseDate
        object.boxOffice = boxOffice as NSDecimalNumber
        return object
    }
}

@objc(RepoMovie)
public final class RepoMovie: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var releaseDate: Date?
    @NSManaged var boxOffice: NSDecimalNumber?
}

extension RepoMovie: RepositoryManagedModel {
    public typealias Unmanaged = Movie
    public var asUnmanaged: Movie {
        return Movie(
            id: self.id ?? UUID(),
            title: self.title ?? "",
            releaseDate: self.releaseDate ?? Date(),
            boxOffice: (self.boxOffice ?? 0) as Decimal,
            objectID: self.objectID
        )
    }

    public func update(from unmanaged: Movie) {
        self.id = unmanaged.id
        self.title = unmanaged.title
        self.releaseDate = unmanaged.releaseDate
        self.boxOffice = NSDecimalNumber(decimal: unmanaged.boxOffice)
    }

    static func fetchRequest() -> NSFetchRequest<RepoMovie> {
        let request = NSFetchRequest<RepoMovie>(entityName: "RepoMovie")
        return request
    }
}
