// CoreDataRepository+Fetch.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

extension CoreDataRepository {
    /// Fetch items from the store with a ``NSFetchRequest``.
    public func fetch<Model: UnmanagedModel>(_ request: NSFetchRequest<Model.ManagedModel>) async
        -> Result<[Model], CoreDataError>
    {
        await context.performInChild { fetchContext in
            try fetchContext.fetch(request).map(Model.init(managed:))
        }
    }

    /// Fetch items from the store with a ``NSFetchRequest`` and receive updates as the store changes.
    public func fetchStreamProvider<Model: UnmanagedModel>(
        _ request: NSFetchRequest<Model.ManagedModel>,
        of _: Model.Type
    ) -> AsyncStream<Result<[Model], CoreDataError>> {
        AsyncStream { continuation in
            let subscription = FetchStreamProvider(
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
    public func fetchThrowingStreamProvider<Model: UnmanagedModel>(
        _ request: NSFetchRequest<Model.ManagedModel>,
        of _: Model.Type
    ) -> AsyncThrowingStream<[Model], Error> {
        AsyncThrowingStream { continuation in
            let subscription = FetchThrowingStreamProvider(
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
