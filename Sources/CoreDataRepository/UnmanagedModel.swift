// UnmanagedModel.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

/// Protocol for a value type that corresponds to a ``NSManagedObject`` subclass
public protocol UnmanagedModel: UnmanagedReadOnlyModel {
    /// URL representation of the ``ManagedModel``'s ``NSManagedObjectID``
    ///
    /// A `nil` value should mean that this instance has not been saved in the repository
    var managedIdUrl: URL? { get set }

    /// Create an instance of ``ManagedModel`` in the provided ``NSManagedObjectContext``
    func asManagedModel(in context: NSManagedObjectContext) throws -> ManagedModel

    /// Update the properties of the ``ManagedModel`` instance from `self`
    func updating(managed: ManagedModel) throws
}
