// CoreDataRepository.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CoreData
import Foundation

/// A CoreData repository with typical create, read, update, and delete endpoints
public final class CoreDataRepository {

    /// CoreData context the repository uses. A child or 'scratch' context is usually created from this context for work to be performed in.
    public let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}
