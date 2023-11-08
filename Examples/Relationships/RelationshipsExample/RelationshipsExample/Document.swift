// Document.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import CoreDataRepository
import Foundation

public struct Document: Hashable, Sendable, Identifiable {
    public let id: UUID
    public var content: String
    public var managedIdUrl: URL?

    public init(id: UUID, content: String, managedIdUrl: URL? = nil) {
        self.id = id
        self.content = content
        self.managedIdUrl = managedIdUrl
    }
}

extension Document: UnmanagedModel {
    public init(managed: Managed) throws {
        self.init(
            id: managed.id,
            content: managed.content,
            managedIdUrl: managed.objectID.uriRepresentation()
        )
    }

    public func asManagedModel(in context: NSManagedObjectContext) throws -> Managed {
        let managed = Managed(context: context)
        try updating(managed: managed)
        return managed
    }

    public func updating(managed: Document.Managed) throws {
        managed.id = id
    }
}

extension Document {
    @objc(ManagedDocument)
    public final class Managed: NSManagedObject {
        @NSManaged var id: UUID
        @NSManaged var content: String
    }
}

extension Document.Managed {
    static func fetchRequest() -> NSFetchRequest<Document.Managed> {
        let request = NSFetchRequest<Document.Managed>(entityName: "ManagedDocument")
        return request
    }
}

extension Document.Managed {
    static var entityDescription: NSEntityDescription {
        let desc = NSEntityDescription()
        desc.name = "ManagedDocument"
        desc.managedObjectClassName = desc.name
        desc.properties = [
            idDescription,
        ]
        desc.uniquenessConstraints = [[idDescription]]
        return desc
    }

    static var idDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "id"
        desc.attributeType = .UUIDAttributeType
        return desc
    }

    static var contentDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "content"
        desc.attributeType = .stringAttributeType
        desc.defaultValue = ""
        return desc
    }
}
