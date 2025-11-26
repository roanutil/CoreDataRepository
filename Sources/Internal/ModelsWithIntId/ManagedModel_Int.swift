// ManagedModel_Int.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

@objc(ManagedModel_IntId)
package final class ManagedModel_IntId: BaseManagedModel {
    @NSManaged package var id: Int
}

extension ManagedModel_IntId {
    override package class func entity() -> NSEntityDescription {
        entityDescription
    }

    package nonisolated(unsafe) static let entityDescription: NSEntityDescription = {
        let desc = NSEntityDescription()
        desc.name = "ManagedModel_IntId"
        desc.managedObjectClassName = NSStringFromClass(ManagedModel_IntId.self)
        desc.properties = attributeDescriptions(appending: [idDescription])
        desc.uniquenessConstraints = [[idDescription]]
        desc.indexes = [NSFetchIndexDescription(
            name: "id",
            elements: [NSFetchIndexElementDescription(
                property: ManagedModel_IntId.idDescription,
                collationType: .binary
            )]
        )]
        return desc
    }()

    package static var idDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "id"
        desc.attributeType = .integer64AttributeType
        return desc
    }
}
