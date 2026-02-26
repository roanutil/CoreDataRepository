// CoreDataRepository+Fetch.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

@preconcurrency import CoreData
import Foundation

extension CoreDataRepository {
    /// Fetch items from the store with a ``NSFetchRequest``.
    @inlinable
    public func fetch<Model: FetchableUnmanagedModel>(
        _ request: NSFetchRequest<Model.ManagedModel>,
        as _: Model.Type
    ) async -> Result<[Model], CoreDataError> {
        let context = Transaction.current?.context ?? context
        return await context.performInChild { fetchContext in
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
    ///
    /// This endpoint allows separate fetch requests for fetching and change tracking. There are times where CoreData
    /// will not recognize changes with a specific predicate. The fix, is to use a simplified predicate for change
    /// tracking and the full predicate for fetching.
    @inlinable
    public func fetchSubscription<Model: FetchableUnmanagedModel>(
        request: NSFetchRequest<Model.ManagedModel>,
        changeTrackingRequest: NSFetchRequest<Model.ManagedModel>,
        of _: Model.Type
    ) -> AsyncStream<Result<[Model], CoreDataError>> {
        AsyncStream { continuation in
            let subscription = FetchSubscription(
                fetchRequest: request,
                fetchResultControllerRequest: changeTrackingRequest,
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

    /// Fetch items from the store with a ``NSFetchRequest`` and receive updates as the store changes.
    ///
    /// This endpoint allows separate fetch requests for fetching and change tracking. There are times where CoreData
    /// will not recognize changes with a specific predicate. The fix, is to use a simplified predicate for change
    /// tracking and the full predicate for fetching.
    @inlinable
    public func fetchThrowingSubscription<Model: FetchableUnmanagedModel>(
        request: NSFetchRequest<Model.ManagedModel>,
        changeTrackingRequest: NSFetchRequest<Model.ManagedModel>,
        of _: Model.Type
    ) -> AsyncThrowingStream<[Model], Error> {
        AsyncThrowingStream { continuation in
            let subscription = FetchThrowingSubscription(
                fetchRequest: request,
                fetchResultControllerRequest: changeTrackingRequest,
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
    public func fetch<Managed: NSManagedObject, Output>(
        request: NSFetchRequest<Managed>,
        operation: @escaping (_ results: [Managed]) throws -> Output
    ) async -> Result<Output, CoreDataError> {
        let context = Transaction.current?.context ?? context
        return await context.performInChild { fetchContext in
            try operation(fetchContext.fetch(request))
        }
    }
}
