// WritableUnmanagedModel.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

/// Protocol for a value type for writing a ``NSManagedObject`` subclass to the `CoreData` store.
///
/// A separate protocol for creating, updating, and deleting entries in the `CoreData` store enables more granular
/// control of behavior.
public protocol WritableUnmanagedModel: Sendable {
    associatedtype ManagedModel: NSManagedObject
    /// Create an instance of ``ManagedModel`` in the provided ``NSManagedObjectContext``
    func asManagedModel(in context: NSManagedObjectContext) throws -> ManagedModel

    /// Update the properties of the ``ManagedModel`` instance from `self`
    func updating(managed: ManagedModel) throws
}

extension WritableUnmanagedModel {
    @inlinable
    public func asManagedModel(in context: NSManagedObjectContext) throws -> ManagedModel {
        let managed = ManagedModel(context: context)
        try updating(managed: managed)
        return managed
    }
}
