// BaseManagedModel.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData

package class BaseManagedModel: NSManagedObject {
    @NSManaged package var bool: Bool
    @NSManaged package var date: Date
    @NSManaged package var decimal: NSDecimalNumber
    @NSManaged package var double: Double
    @NSManaged package var float: Float
    @NSManaged package var int: Int
    @NSManaged package var string: String
    @NSManaged package var uuid: UUID

    @inlinable
    package func defaulted(
        bool: Bool = true,
        date: Date = Date(),
        decimal: Decimal = 0,
        double: Double = 0,
        float: Float = 0,
        int: Int = 0,
        string: String = "",
        uuid: UUID = UUID()
    ) {
        self.bool = bool
        self.date = date
        self.decimal = decimal as NSDecimalNumber
        self.double = double
        self.float = float
        self.int = int
        self.string = string
        self.uuid = uuid
    }

    @inlinable
    package func seeded(_ seed: Int) {
        let _uuid = UUID(uniform: seed.description.first!)
        bool = seed.isMultiple(of: 2) ? true : false
        date = Date(timeIntervalSinceReferenceDate: TimeInterval(seed))
        decimal = Decimal(seed) as NSDecimalNumber
        double = Double(seed)
        float = Float(seed)
        int = seed
        string = seed.description
        uuid = _uuid
    }
}

extension BaseManagedModel {
    package static func attributeDescriptions(appending: [NSAttributeDescription] = []) -> [NSAttributeDescription] {
        var _desc = [
            boolDescription,
            dateDescription,
            decimalDescription,
            doubleDescription,
            floatDescription,
            intDescription,
            stringDescription,
            uuidDescription,
        ]
        _desc.append(contentsOf: appending)
        return _desc
    }

    package static var boolDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "bool"
        desc.attributeType = .booleanAttributeType
        return desc
    }

    package static var dateDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "date"
        desc.attributeType = .dateAttributeType
        return desc
    }

    package static var decimalDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "decimal"
        desc.attributeType = .decimalAttributeType
        return desc
    }

    package static var doubleDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "double"
        desc.attributeType = .doubleAttributeType
        return desc
    }

    package static var floatDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "float"
        desc.attributeType = .floatAttributeType
        return desc
    }

    package static var intDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "int"
        desc.attributeType = .integer64AttributeType
        return desc
    }

    package static var stringDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "string"
        desc.attributeType = .stringAttributeType
        return desc
    }

    package static var uuidDescription: NSAttributeDescription {
        let desc = NSAttributeDescription()
        desc.name = "uuid"
        desc.attributeType = .UUIDAttributeType
        return desc
    }
}
