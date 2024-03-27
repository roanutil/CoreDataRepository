// CoreDataRepository+CRUD.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

extension CoreDataRepository {
    /// Create an instance in the store.
    public func create<Model: UnmanagedModel>(
        _ item: Model,
        transactionAuthor: String? = nil
    ) async -> Result<Model, CoreDataError> {
        await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            let object = Model.ManagedModel(context: scratchPad)
            let tempObjectId = object.objectID
            try item.updating(managed: object)
            try scratchPad.save()
            try context.performAndWait {
                context.transactionAuthor = transactionAuthor
                do {
                    try context.save()
                } catch {
                    let parentContextObject = context.object(with: tempObjectId)
                    context.delete(parentContextObject)
                    throw error
                }
                context.transactionAuthor = nil
            }
            try scratchPad.obtainPermanentIDs(for: [object])
            return try Model(managed: object)
        }
    }

    /// Read an instance from the store.
    public func read<Model: UnmanagedReadOnlyModel>(
        _ url: URL,
        of _: Model.Type
    ) async -> Result<Model, CoreDataError> {
        await context.performInChild(schedule: .enqueued) { readContext in
            let id = try readContext.objectId(from: url).get()
            let object = try readContext.notDeletedObject(for: id)
            let repoManaged: Model.ManagedModel = try object.asManagedModel()
            return try Model(managed: repoManaged)
        }
    }

    /// Update the store with an unmanaged model.
    public func update<Model: UnmanagedModel>(
        _ url: URL,
        with item: Model,
        transactionAuthor: String? = nil
    ) async -> Result<Model, CoreDataError> {
        await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            let id = try scratchPad.objectId(from: url).get()
            let object = try scratchPad.notDeletedObject(for: id)
            let repoManaged: Model.ManagedModel = try object.asManagedModel()
            try item.updating(managed: repoManaged)
            try scratchPad.save()
            try context.performAndWait {
                context.transactionAuthor = transactionAuthor
                try context.save()
                context.transactionAuthor = nil
            }
            return try Model(managed: repoManaged)
        }
    }

    /// Delete an instance from the store.
    public func delete(
        _ url: URL,
        transactionAuthor: String? = nil
    ) async -> Result<Void, CoreDataError> {
        await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            let id = try scratchPad.objectId(from: url).get()
            let object = try scratchPad.notDeletedObject(for: id)
            object.prepareForDeletion()
            scratchPad.delete(object)
            try scratchPad.save()
            try context.performAndWait {
                context.transactionAuthor = transactionAuthor
                try context.save()
                context.transactionAuthor = nil
            }
            return ()
        }
    }

    /// Subscribe to updates of an instance in the store.
    public func readSubscription<Model: UnmanagedReadOnlyModel>(_ url: URL, of _: Model.Type)
        -> AsyncStream<Result<Model, CoreDataError>>
    {
        let readContext = context.childContext()
        return AsyncStream { continuation in
            let provider: ReadSubscription<Model>
            switch readContext.objectId(from: url) {
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
    public func readThrowingSubscription<Model: UnmanagedReadOnlyModel>(_ url: URL, of _: Model.Type)
        -> AsyncThrowingStream<Model, Error>
    {
        let readContext = context.childContext()
        return AsyncThrowingStream { continuation in
            let provider: ReadThrowingSubscription<Model>
            switch readContext.objectId(from: url) {
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
