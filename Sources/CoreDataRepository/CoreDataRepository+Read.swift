// CoreDataRepository+Read.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData

extension CoreDataRepository {
    /// Read an instance from the store.
    @inlinable
    public func read<Model: ReadableUnmanagedModel>(
        _ item: Model
    ) async -> Result<Model, CoreDataError> {
        await context.performInChild(schedule: .enqueued) { readContext in
            let managed = try item.readManaged(from: readContext)
            return try Model(managed: managed)
        }
    }

    /// Read an instance from the store.
    @inlinable
    public func read<Model>(
        _ id: Model.UnmanagedId,
        of _: Model.Type
    ) async -> Result<Model, CoreDataError> where Model: IdentifiedUnmanagedModel {
        await context.performInChild(schedule: .enqueued) { readContext in
            let managed = try Model.readManaged(id: id, from: readContext)
            return try Model(managed: managed)
        }
    }

    /// Read an instance from the store.
    @inlinable
    public func read<Model>(
        _ managedId: NSManagedObjectID,
        of _: Model.Type
    ) async -> Result<Model, CoreDataError> where Model: FetchableUnmanagedModel {
        await context.performInChild(schedule: .enqueued) { readContext in
            let object = try readContext.notDeletedObject(for: managedId)
            let managed: Model.ManagedModel = try object.asManagedModel()
            return try Model(managed: managed)
        }
    }

    /// Read an instance from the store.
    @inlinable
    public func read<Model>(
        _ managedIdUrl: URL,
        of _: Model.Type
    ) async -> Result<Model, CoreDataError> where Model: FetchableUnmanagedModel {
        await context.performInChild(schedule: .enqueued) { readContext in
            let id = try readContext.objectId(from: managedIdUrl).get()
            let object = try readContext.notDeletedObject(for: id)
            let repoManaged: Model.ManagedModel = try object.asManagedModel()
            return try Model(managed: repoManaged)
        }
    }

    /// Subscribe to updates of an instance in the store.
    @inlinable
    public func readSubscription<Model: ReadableUnmanagedModel>(_ item: Model)
        -> AsyncStream<Result<Model, CoreDataError>>
    {
        AsyncStream { [context] continuation in
            let provider: ReadSubscription<Model>
            switch context.performInChildAndWait({ readContext in
                try (item.readManaged(from: readContext).objectID, readContext)
            }) {
            case let .success((managedId, readContext)):
                provider = ReadSubscription<Model>(
                    objectId: managedId,
                    context: readContext,
                    continuation: continuation
                )
            case let .failure(error):
                continuation.yield(.failure(error))
                continuation.finish()
                return
            }
            provider.start()
            provider.manualFetch()
            continuation.onTermination = { _ in
                provider.cancel()
            }
        }
    }

    /// Subscribe to updates of an instance in the store.
    @inlinable
    public func readSubscription<Model: IdentifiedUnmanagedModel>(
        _ id: Model.UnmanagedId,
        of _: Model.Type
    )
        -> AsyncStream<Result<Model, CoreDataError>>
    {
        AsyncStream { [context] continuation in
            let provider: ReadSubscription<Model>
            switch context.performInChildAndWait({ readContext in
                try (Model.readManaged(id: id, from: readContext).objectID, readContext)
            }) {
            case let .success((managedId, readContext)):
                provider = ReadSubscription<Model>(
                    objectId: managedId,
                    context: readContext,
                    continuation: continuation
                )
            case let .failure(error):
                continuation.yield(.failure(error))
                continuation.finish()
                return
            }
            provider.start()
            provider.manualFetch()
            continuation.onTermination = { _ in
                provider.cancel()
            }
        }
    }

    /// Subscribe to updates of an instance in the store.
    @inlinable
    public func readSubscription<Model: ReadableUnmanagedModel>(
        _ managedId: NSManagedObjectID,
        of _: Model.Type
    )
        -> AsyncStream<Result<Model, CoreDataError>>
    {
        let readContext = context.childContext()
        return AsyncStream { continuation in
            let provider = ReadSubscription<Model>(
                objectId: managedId,
                context: readContext,
                continuation: continuation
            )
            provider.start()
            provider.manualFetch()
            continuation.onTermination = { _ in
                provider.cancel()
            }
        }
    }

    /// Subscribe to updates of an instance in the store.
    @inlinable
    public func readSubscription<Model: ReadableUnmanagedModel>(
        _ managedIdUrl: URL,
        of _: Model.Type
    )
        -> AsyncStream<Result<Model, CoreDataError>>
    {
        let readContext = context.childContext()
        return AsyncStream { continuation in
            let provider: ReadSubscription<Model>
            switch readContext.objectId(from: managedIdUrl) {
            case let .success(objectId):
                provider = ReadSubscription<Model>(
                    objectId: objectId,
                    context: readContext,
                    continuation: continuation
                )
            case let .failure(error):
                continuation.yield(.failure(error))
                continuation.finish()
                return
            }
            provider.start()
            provider.manualFetch()
            continuation.onTermination = { _ in
                provider.cancel()
            }
        }
    }

    /// Subscribe to updates of an instance in the store.
    @inlinable
    public func readThrowingSubscription<Model: ReadableUnmanagedModel>(_ item: Model)
        -> AsyncThrowingStream<Model, Error>
    {
        AsyncThrowingStream { continuation in
            let provider: ReadThrowingSubscription<Model>
            switch context.performInChildAndWait({ readContext in
                try (item.readManaged(from: readContext).objectID, readContext)
            }) {
            case let .success((managedId, readContext)):
                provider = ReadThrowingSubscription<Model>(
                    objectId: managedId,
                    context: readContext,
                    continuation: continuation
                )
            case let .failure(error):
                continuation.yield(with: .failure(error))
                continuation.finish()
                return
            }
            provider.start()
            provider.manualFetch()
            continuation.onTermination = { _ in
                provider.cancel()
            }
        }
    }

    /// Subscribe to updates of an instance in the store.
    @inlinable
    public func readThrowingSubscription<Model: IdentifiedUnmanagedModel>(
        _ id: Model.UnmanagedId,
        of _: Model.Type
    )
        -> AsyncThrowingStream<Model, Error>
    {
        AsyncThrowingStream { [context] continuation in
            let provider: ReadThrowingSubscription<Model>
            switch context.performInChildAndWait({ readContext in
                try (Model.readManaged(id: id, from: readContext).objectID, readContext)
            }) {
            case let .success((managedId, readContext)):
                provider = ReadThrowingSubscription<Model>(
                    objectId: managedId,
                    context: readContext,
                    continuation: continuation
                )
            case let .failure(error):
                continuation.yield(with: .failure(error))
                continuation.finish()
                return
            }
            provider.start()
            provider.manualFetch()
            continuation.onTermination = { _ in
                provider.cancel()
            }
        }
    }

    /// Subscribe to updates of an instance in the store.
    @inlinable
    public func readThrowingSubscription<Model: ReadableUnmanagedModel>(
        _ managedId: NSManagedObjectID,
        of _: Model.Type
    )
        -> AsyncThrowingStream<Model, Error>
    {
        let readContext = context.childContext()
        return AsyncThrowingStream { continuation in
            let provider: ReadThrowingSubscription<Model>
            provider = ReadThrowingSubscription<Model>(
                objectId: managedId,
                context: readContext,
                continuation: continuation
            )
            provider.start()
            provider.manualFetch()
            continuation.onTermination = { _ in
                provider.cancel()
            }
        }
    }

    /// Subscribe to updates of an instance in the store.
    @inlinable
    public func readThrowingSubscription<Model: ReadableUnmanagedModel>(_ managedIdUrl: URL, of _: Model.Type)
        -> AsyncThrowingStream<Model, Error>
    {
        let readContext = context.childContext()
        return AsyncThrowingStream { continuation in
            let provider: ReadThrowingSubscription<Model>
            switch readContext.objectId(from: managedIdUrl) {
            case let .success(objectId):
                provider = ReadThrowingSubscription<Model>(
                    objectId: objectId,
                    context: readContext,
                    continuation: continuation
                )
            case let .failure(error):
                continuation.yield(with: .failure(error))
                continuation.finish()
                return
            }
            provider.start()
            provider.manualFetch()
            continuation.onTermination = { _ in
                provider.cancel()
            }
        }
    }
}
