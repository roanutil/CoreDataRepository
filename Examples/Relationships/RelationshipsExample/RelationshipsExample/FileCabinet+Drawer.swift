// FileCabinet+Drawer.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import CoreDataRepository
import Foundation

extension FileCabinet {
    public struct Drawer: Hashable, Sendable, Identifiable {
        public let id: UUID
        public var documents: [Document]
        public var managedIdUrl: URL?

        public init(id: UUID, documents: [Document], managedIdUrl: URL? = nil) {
            self.id = id
            self.documents = documents
            self.managedIdUrl = managedIdUrl
        }
    }
}

extension FileCabinet.Drawer: UnmanagedModel {
    public init(managed: Managed) throws {
        try self.init(
            id: managed.id,
            documents: managed.managedDocuments.map(Document.init(managed:)),
            managedIdUrl: managed.objectID.uriRepresentation()
        )
    }

    public func asManagedModel(in context: NSManagedObjectContext) throws -> FileCabinet.Drawer.Managed {
        let managed = Managed(context: context)
        try updating(managed: managed)
        return managed
    }

    public func updating(managed: FileCabinet.Drawer.Managed) throws {
        managed.id = id
        managed.removeDocuments(managed.documents)
        try managed
            .addDocuments(NSArray(
                array: documents
                    .map { try $0.asManagedModel(in: managed.managedObjectContext!) }
            ))
    }
}

extension FileCabinet.Drawer {
    @objc(ManagedFileCabinetDrawer)
    public final class Managed: NSManagedObject {
        @NSManaged var id: UUID
        @NSManaged var documents: NSArray

        var managedDocuments: [Document.Managed] {
            (documents as? [Document.Managed]) ?? []
        }
    }
}

extension FileCabinet.Drawer.Managed {
    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: Document.Managed)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: Document.Managed)

    @objc(addDocuments:)
    @NSManaged public func addDocuments(_ values: NSArray)

    @objc(removeDocuments:)
    @NSManaged public func removeDocuments(_ values: NSArray)
}

extension FileCabinet.Drawer.Managed {
    static var entityDescription: NSEntityDescription {
        let desc = NSEntityDescription()
        desc.name = "ManagedFileCabinetDrawer"
        desc.managedObjectClassName = desc.name
        desc.properties = [
            idDescription,
            documentsDescription,
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

    static var documentsDescription: NSRelationshipDescription {
        let desc = NSRelationshipDescription()
        desc.name = "documents"
        desc.isOrdered = true
        desc.deleteRule = .cascadeDeleteRule
        desc.destinationEntity = Document.Managed.entityDescription
        desc.minCount = 0
        desc.maxCount = 0
        return desc
    }
}
