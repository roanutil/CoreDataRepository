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
        if let persistentId, let existingObject: Persistent = context.model(for: persistentId) as? Persistent {
            updating(persisted: existingObject)
            return existingObject
        } else {
            let object = RepoMovie(proxyID: id, title: title, releaseDate: releaseDate, boxOffice: boxOffice)
            context.insert(object)
            return object
        }
    }

    public func updating(persisted: RepoMovie) {
        persisted.proxyID = id
        persisted.title = title
        persisted.releaseDate = releaseDate
        persisted.boxOffice = boxOffice
    }

    public init(persisted: RepoMovie) {
        self.init(
            id: persisted.proxyID,
            title: persisted.title,
            releaseDate: persisted.releaseDate,
            boxOffice: persisted.boxOffice,
            persistentId: persisted.persistentModelID
        )
    }
}

@Model
public final class RepoMovie: IdentifiableByProxy {
    public var proxyID: UUID
    public var title: String
    public var releaseDate: Date
    public var boxOffice: Decimal

    public init(proxyID: UUID, title: String, releaseDate: Date, boxOffice: Decimal) {
        self.proxyID = proxyID
        self.title = title
        self.releaseDate = releaseDate
        self.boxOffice = boxOffice
    }
}
