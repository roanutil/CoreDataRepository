// RepositoryManagedModel.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData

/// A protocol for a CoreData NSManagedObject sub class that has a corresponding value type
public protocol RepositoryManagedModel: NSManagedObject {
    associatedtype Unmanaged: UnmanagedModel where Unmanaged.RepoManaged == Self
    /// Returns a value type instance of `self`
    var asUnmanaged: Unmanaged { get }
    /// Create `self` from a corresponding instance of `UnmanagedModel`. Should not save the context.
    func create(from unmanaged: Unmanaged)
    /// Update `self` from a corresponding instance of `UnmanagedModel`. Should not save the context.
    func update(from unmanaged: Unmanaged)
}
