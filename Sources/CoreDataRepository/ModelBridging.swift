//
//  ModelBridging.swift
//
//  Created by Andrew Roan on 1/15/21.
//

import CoreData
// MARK: Managed
/// A protocol for a CoreData NSManagedObject sub class that has a corresponding value type
public protocol RepositoryManagedModel: NSManagedObject {
    associatedtype Unmanaged: UnmanagedModel where Unmanaged.RepoManaged == Self
    /// Returns a value type instance of `self`
    var asUnmanaged: Unmanaged { get }
    /// Update `self` from a corresponding instance of `UnmanagedModel`. Should not save the context.
    func update(from unmanaged: Unmanaged)
}

// MARK: Unmanaged
/// A protocol for a value type that corresponds to a RepositoryManagedModel
public protocol UnmanagedModel: Hashable {
    associatedtype RepoManaged: RepositoryManagedModel where RepoManaged.Unmanaged == Self
    /// Keep an reference to the corresponding `RepositoryManagedModel` instance for getting it later. Optional since a new instance won't have a record in CoreData.
    var objectID: NSManagedObjectID? { get set }
    /// Returns a RepositoryManagedModel instance of `self`
    func asRepoManaged(in context: NSManagedObjectContext) -> RepoManaged
}
