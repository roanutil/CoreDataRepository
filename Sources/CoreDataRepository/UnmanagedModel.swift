// UnmanagedModel.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

/// A protocol for a value type that corresponds to a ``NSManagedObject`` subclass
public protocol UnmanagedModel: Equatable {
    /// The ``NSManagedObject`` subclass `Self` corresponds to
    associatedtype ManagedModel: NSManagedObject

    /// URL representation of the ``ManagedModel``'s ``NSManagedObjectID``
    ///
    /// A `nil` value should mean that this instance has not been saved in the repository
    var managedIdUrl: URL? { get set }

    /// Create an instance of ``ManagedModel`` in the provided ``NSManagedObjectContext``
    func asManagedModel(in context: NSManagedObjectContext) throws -> ManagedModel

    /// Update the properties of the ``ManagedModel`` instance from `self`
    func updating(managed: ManagedModel) throws

    /// Initialize of new instance of `Self` from an instance of ``ManagedModel``
    init(managed: ManagedModel) throws

    /// ``NSFetchRequest`` for ``ManagedModel`` with a strongly typed ``NSFetchRequest.ResultType``
    static func managedFetchRequest() -> NSFetchRequest<ManagedModel>
}

extension UnmanagedModel {
    public static func managedFetchRequest() -> NSFetchRequest<ManagedModel> {
        NSFetchRequest<ManagedModel>(
            entityName: ManagedModel.entity().name ?? ManagedModel.entity()
                .managedObjectClassName
        )
    }
}
