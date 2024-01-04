// FileCabinet.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import CoreDataRepository
import Foundation

public struct FileCabinet: Hashable, Sendable, Identifiable {
    public let id: UUID
    public var drawers: [Drawer]
    public var managedIdUrl: URL?

    public init(id: UUID, drawers: [Drawer], managedIdUrl: URL? = nil) {
        self.id = id
        self.drawers = drawers
        self.managedIdUrl = managedIdUrl
    }
}

extension FileCabinet: UnmanagedModel {
    public init(managed: Managed) throws {
        try self.init(
            id: managed.id,
            drawers: managed.managedDrawers.map(Drawer.init(managed:)),
            managedIdUrl: managed.objectID.uriRepresentation()
        )
    }

    public func asManagedModel(in context: NSManagedObjectContext) throws -> Managed {
        let managed = Managed(context: context)
        try updating(managed: managed)
        return managed
    }

    public func updating(managed: Managed) throws {
        managed.id = id
        managed.removeDrawers(managed.drawers)
        try managed
            .addDrawers(NSArray(
                array: drawers
                    .map { try $0.asManagedModel(in: managed.managedObjectContext!) }
            ))
    }
}

extension FileCabinet {
    @objc(ManagedFileCabinet)
    public final class Managed: NSManagedObject {
        @NSManaged var id: UUID
        @NSManaged var drawers: NSArray

        var managedDrawers: [Drawer.Managed] {
            (drawers as? [Drawer.Managed]) ?? []
        }
    }
}

extension FileCabinet.Managed {
    @objc(addDrawersObject:)
    @NSManaged public func addToDrawers(_ value: FileCabinet.Drawer.Managed)

    @objc(removeDrawersObject:)
    @NSManaged public func removeFromDrawers(_ value: FileCabinet.Drawer.Managed)

    @objc(addDrawers:)
    @NSManaged public func addDrawers(_ values: NSArray)

    @objc(removeDrawers:)
    @NSManaged public func removeDrawers(_ values: NSArray)
}

extension FileCabinet.Managed {
    static var entityDescription: NSEntityDescription {
        let desc = NSEntityDescription()
        desc.name = "ManagedFileCabinet"
        desc.managedObjectClassName = desc.name
        desc.properties = [
            idDescription,
            drawersDescription,
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

    static var drawersDescription: NSRelationshipDescription {
        let desc = NSRelationshipDescription()
        desc.name = "drawers"
        desc.isOrdered = true
        desc.deleteRule = .cascadeDeleteRule
        desc.destinationEntity = FileCabinet.Drawer.Managed.entityDescription
        desc.minCount = 0
        desc.maxCount = 0
        return desc
    }
}
