// CoreDataRepository+Fetch.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

extension CoreDataRepository {
    /// Fetch items from the store with a ``NSFetchRequest``.
    public func fetch<Model: UnmanagedModel>(
        _ request: NSFetchRequest<Model.ManagedModel>,
        as _: Model.Type
    ) async -> Result<[Model], CoreDataError> {
        await context.performInChild { fetchContext in
            try fetchContext.fetch(request).map(Model.init(managed:))
        }
    }

    /// Fetch items from the store with a ``NSFetchRequest`` and receive updates as the store changes.
    public func fetchSubscription<Model: UnmanagedModel>(
        _ request: NSFetchRequest<Model.ManagedModel>,
        of _: Model.Type
    ) -> AsyncStream<Result<[Model], CoreDataError>> {
        AsyncStream { continuation in
            let subscription = FetchSubscription(
                request: request,
                context: context.childContext(),
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }

    /// Fetch items from the store with a ``NSFetchRequest`` and receive updates as the store changes.
    public func fetchThrowingSubscription<Model: UnmanagedModel>(
        _ request: NSFetchRequest<Model.ManagedModel>,
        of _: Model.Type
    ) -> AsyncThrowingStream<[Model], Error> {
        AsyncThrowingStream { continuation in
            let subscription = FetchThrowingSubscription(
                request: request,
                context: context.childContext(),
                continuation: continuation
            )
            continuation.onTermination = { _ in
                subscription.cancel()
            }
            subscription.manualFetch()
        }
    }
}
