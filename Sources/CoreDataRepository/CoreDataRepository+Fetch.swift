// CoreDataRepository+Fetch.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

extension CoreDataRepository {
    /// Fetch items from the store with a ``NSFetchRequest``.
    @inlinable
    public func fetch<Model: FetchableUnmanagedModel>(
        _ request: NSFetchRequest<Model.ManagedModel>,
        as _: Model.Type
    ) async -> Result<[Model], CoreDataError> {
        await context.performInChild { fetchContext in
            try fetchContext.fetch(request).map(Model.init(managed:))
        }
    }

    /// Fetch items from the store with a ``NSFetchRequest`` and receive updates as the store changes.
    @inlinable
    public func fetchSubscription<Model: FetchableUnmanagedModel>(
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
    @inlinable
    public func fetchThrowingSubscription<Model: FetchableUnmanagedModel>(
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

    /// Fetch items from the store with a ``NSFetchRequest`` and transform the results.
    @inlinable
    public func fetch<Managed, Output>(
        request: NSFetchRequest<Managed>,
        operation: @escaping (_ results: [Managed]) throws -> Output
    ) async -> Result<Output, CoreDataError> where Managed: NSManagedObject {
        await context.performInChild { fetchContext in
            try operation(fetchContext.fetch(request))
        }
    }
}
