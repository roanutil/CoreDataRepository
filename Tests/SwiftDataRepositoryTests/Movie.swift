// Movie.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation
import SwiftData
import SwiftDataRepository

public struct Movie: Hashable, Identifiable, Codable {
    public let id: UUID
    public var title: String = ""
    public var releaseDate: Date
    public var boxOffice: Decimal = 0
    public var persistentId: PersistentIdentifier?

    public init(
        id: UUID,
        title: String,
        releaseDate: Date,
        boxOffice: Decimal,
        persistentId: PersistentIdentifier? = nil
    ) {
        self.id = id
        self.title = title
        self.releaseDate = releaseDate
        self.boxOffice = boxOffice
        self.persistentId = persistentId
    }
}

extension Movie: PersistentModelProxy {
    public func asPersistentModel(in context: ModelContext) -> RepoMovie {
        if let persistentId, let existingObject: Persistent = context.registeredObject(for: persistentId) {
            updating(persisted: existingObject)
            return existingObject
        } else {
            let object = RepoMovie(id: id, title: title, releaseDate: releaseDate, boxOffice: boxOffice)
            context.insert(object)
            return object
        }
    }

    public func updating(persisted: RepoMovie) {
        persisted.id = id
        persisted.title = title
        persisted.releaseDate = releaseDate
        persisted.boxOffice = boxOffice
    }

    public init(persisted: RepoMovie) {
        self.init(
            id: persisted.id,
            title: persisted.title,
            releaseDate: persisted.releaseDate,
            boxOffice: persisted.boxOffice,
            persistentId: persisted.objectID
        )
    }
}

@Model
public final class RepoMovie: Identifiable {
    public var id: UUID
    public var title: String
    public var releaseDate: Date
    public var boxOffice: Decimal

    public init(id: UUID, title: String, releaseDate: Date, boxOffice: Decimal) {
        self.id = id
        self.title = title
        self.releaseDate = releaseDate
        self.boxOffice = boxOffice
    }
}
