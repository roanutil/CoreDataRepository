// ManagedIdModel_Int.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import CoreDataRepository
import Foundation

package struct ManagedIdModel_IntId: Hashable, Sendable {
    package let id: Int
    package var bool: Bool
    package var date: Date
    package var decimal: Decimal
    package var double: Double
    package var float: Float
    package var int: Int
    package var string: String
    package var uuid: UUID
    package var managedId: NSManagedObjectID?

    @inlinable
    package init(
        bool: Bool,
        date: Date,
        decimal: Decimal,
        double: Double,
        float: Float,
        id: Int,
        int: Int,
        managedId: NSManagedObjectID?,
        string: String,
        uuid: UUID
    ) {
        self.bool = bool
        self.date = date
        self.decimal = decimal
        self.double = double
        self.float = float
        self.id = id
        self.int = int
        self.managedId = managedId
        self.string = string
        self.uuid = uuid
    }

    @inlinable
    package init(fetchable other: FetchableModel_IntId) {
        self.init(
            bool: other.bool,
            date: other.date,
            decimal: other.decimal,
            double: other.double,
            float: other.float,
            id: other.int,
            int: other.int,
            managedId: nil,
            string: other.string,
            uuid: other.uuid
        )
    }

    @inlinable
    package var asDict: [String: Any] {
        [
            "bool": bool,
            "date": date,
            "decimal": decimal,
            "double": double,
            "float": float,
            "id": id,
            "int": int,
            "string": string,
            "uuid": uuid,
        ]
    }

    @inlinable
    package static func defaulted(
        bool: Bool = true,
        date: Date = Date(),
        decimal: Decimal = 0,
        double: Double = 0,
        float: Float = 0,
        id: Int = 0,
        int: Int = 0,
        managedId: NSManagedObjectID? = nil,
        string: String = "",
        uuid: UUID = UUID()
    ) -> Self {
        Self(
            bool: bool,
            date: date,
            decimal: decimal,
            double: double,
            float: float,
            id: id,
            int: int,
            managedId: managedId,
            string: string,
            uuid: uuid
        )
    }

    @inlinable
    package func removingManagedId() -> Self {
        Self(
            bool: bool,
            date: date,
            decimal: decimal,
            double: double,
            float: float,
            id: id,
            int: int,
            managedId: nil,
            string: string,
            uuid: uuid
        )
    }

    @inlinable
    package static func seeded(_ seed: Int) -> Self {
        let _uuid = UUID(uniform: seed.description.first!)
        return Self(
            bool: seed.isMultiple(of: 2) ? true : false,
            date: Date(timeIntervalSinceReferenceDate: TimeInterval(seed)),
            decimal: Decimal(seed),
            double: Double(seed),
            float: Float(seed),
            id: seed,
            int: seed,
            managedId: nil,
            string: seed.description,
            uuid: _uuid
        )
    }
}

extension ManagedIdModel_IntId: ManagedIdReferencable {}

extension ManagedIdModel_IntId: FetchableUnmanagedModel {
    package init(managed: ManagedModel_IntId) throws {
        self.init(
            bool: managed.bool,
            date: managed.date,
            decimal: managed.decimal as Decimal,
            double: managed.double,
            float: managed.float,
            id: managed.id,
            int: managed.int,
            managedId: managed.objectID,
            string: managed.string,
            uuid: managed.uuid
        )
    }
}

extension ManagedIdModel_IntId: ReadableUnmanagedModel {}

extension ManagedIdModel_IntId: WritableUnmanagedModel {
    @inlinable
    package func updating(managed: ManagedModel_IntId) throws {
        managed.bool = bool
        managed.date = date
        managed.decimal = decimal as NSDecimalNumber
        managed.double = double
        managed.float = float
        managed.id = id
        managed.int = int
        managed.string = string
        managed.uuid = uuid
    }
}

extension ManagedIdModel_IntId: Comparable {
    package static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.int < rhs.int
    }
}
