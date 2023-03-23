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
    // MARK: Properties

    /// CoreData context the repository uses
    public let context: NSManagedObjectContext
    var subscriptions = [SubscriptionProvider]()
    var cancellables = Set<AnyCancellable>()

    // MARK: Init

    /// Initializes a CRUDRepository
    /// - Parameters
    ///     - context: NSManagedObjectContext
    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}
