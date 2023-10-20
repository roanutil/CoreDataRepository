// CoreDataRepository.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

/// A wrapper around CoreData that improves the ergonomics and safety of using CoreData.
///
/// CoreDataRepository only exposes value types that bridge to the internal ``NSManagedObject`` sub-classes. This makes
/// it a lot easier to use CoreData
/// asynchronously. ``NSManagedObject``s are not thread safe and are not simple Swift classes.
///
/// CRUD, batch CRUD, fetch, and aggregate operations are available.
///
/// For batch operations, there are options that use ``NSBatchInsertRequest``, ``NSBatchUpdateRequest``, and
/// ``NSBatchDeleteRequest`` in
/// addition to non-atomic options that individually perform the operation on each item.
///
/// For fetch and aggregate operations, there are additional subscription and throwing subscription options.
/// StreamProviders return an ``AsyncStream`` of
/// ``Result``s with strongly typed errors. Throwing subscriptions return an ``AsyncThrowingStream``.
public final class CoreDataRepository {
    /// CoreData context the repository uses. A child or 'scratch' context is usually created from this context for work
    /// to be performed in.
    public let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}
