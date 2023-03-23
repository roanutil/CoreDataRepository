// UnmanagedModel.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

/// A protocol for a value type that corresponds to a RepositoryManagedModel
public protocol UnmanagedModel: Equatable {
    associatedtype RepoManaged: RepositoryManagedModel where RepoManaged.Unmanaged == Self
    /// Keep an reference to the corresponding `RepositoryManagedModel` instance for getting it later.
    /// Optional since a new instance won't have a record in CoreData.
    var managedRepoUrl: URL? { get set }
    /// Returns a RepositoryManagedModel instance of `self`
    func asRepoManaged(in context: NSManagedObjectContext) -> RepoManaged
}
