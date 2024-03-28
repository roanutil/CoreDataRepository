// CoreDataRepository+Batch.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

extension CoreDataRepository {
    /// Execute a NSBatchInsertRequest against the store.
    @inlinable
    public func insert(
        _ request: NSBatchInsertRequest,
        transactionAuthor: String? = nil
    ) async -> Result<NSBatchInsertResult, CoreDataError> {
        await context.performInScratchPad { [context] scratchPad in
            context.transactionAuthor = transactionAuthor
            guard let result = try scratchPad.execute(request) as? NSBatchInsertResult else {
                context.transactionAuthor = nil
                throw CoreDataError.fetchedObjectFailedToCastToExpectedType
            }
            context.transactionAuthor = nil
            return result
        }
    }

    /// Create a batch of unmanaged models.
    ///
    /// This operation is non-atomic. Each instance may succeed or fail individually.
    @inlinable
    public func create<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> (success: [Model], failed: [CoreDataBatchError<Model>]) {
        var successes = [Model]()
        var failures = [CoreDataBatchError<Model>]()
        await withTaskGroup(of: Result<Model, CoreDataBatchError<Model>>.self, body: { [weak self] group in
            guard let self else {
                group.cancelAll()
                return
            }
            for item in items {
                let added = group.addTaskUnlessCancelled {
                    async let result: Result<Model, CoreDataError> = self
                        .create(item, transactionAuthor: transactionAuthor)
                    switch await result {
                    case let .success(created):
                        return .success(created)
                    case let .failure(error):
                        return .failure(CoreDataBatchError(item: item, error: error))
                    }
                }
                if !added {
                    return
                }
            }
            for await result in group {
                switch result {
                case let .success(success):
                    successes.append(success)
                case let .failure(failure):
                    failures.append(failure)
                }
            }
        })
        return (success: successes, failed: failures)
    }

    /// Create a batch of unmanaged models.
    @inlinable
    public func createAtomically<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> Result<[Model], CoreDataError> {
        await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            let objects = try items.map { item in
                let object = Model.ManagedModel(context: scratchPad)
                try item.updating(managed: object)
                return object
            }
            try scratchPad.save()
            try context.performAndWait {
                context.transactionAuthor = transactionAuthor
                try context.save()
                context.transactionAuthor = nil
            }
            try scratchPad.obtainPermanentIDs(for: objects)
            return try objects.map(Model.init(managed:))
        }
    }

    /// Read a batch of unmanaged models.
    ///
    /// This operation is non-atomic. Each instance may succeed or fail individually.
    @inlinable
    public func read<Model: UnmanagedModel>(
        urls: [URL],
        as _: Model.Type
    ) async -> (success: [Model], failed: [CoreDataBatchError<URL>]) {
        var successes = [Model]()
        var failures = [CoreDataBatchError<URL>]()
        await withTaskGroup(of: Result<Model, CoreDataBatchError<URL>>.self, body: { [weak self] group in
            guard let self else {
                group.cancelAll()
                return
            }
            for url in urls {
                let added = group.addTaskUnlessCancelled {
                    async let result = self.read(url, of: Model.self)
                    switch await result {
                    case let .success(created):
                        return .success(created)
                    case let .failure(error):
                        return .failure(CoreDataBatchError(item: url, error: error))
                    }
                }
                if !added {
                    return
                }
            }
            for await result in group {
                switch result {
                case let .success(success):
                    successes.append(success)
                case let .failure(failure):
                    failures.append(failure)
                }
            }
        })
        return (success: successes, failed: failures)
    }

    /// Read a batch of unmanaged models.
    @inlinable
    public func readAtomically<Model: UnmanagedModel>(
        urls: [URL],
        as _: Model.Type
    ) async -> Result<[Model], CoreDataError> {
        await context.performInChild(schedule: .enqueued) { readContext in
            try urls.map { url in
                let id = try readContext.objectId(from: url).get()
                let object = try readContext.notDeletedObject(for: id)
                let managed: Model.ManagedModel = try object.asManagedModel()
                return try Model(managed: managed)
            }
        }
    }

    /// Execute a NSBatchUpdateRequest against the store.
    @inlinable
    public func update(
        _ request: NSBatchUpdateRequest,
        transactionAuthor: String? = nil
    ) async -> Result<NSBatchUpdateResult, CoreDataError> {
        await context.performInScratchPad { [context] scratchPad in
            context.transactionAuthor = transactionAuthor
            guard let result = try scratchPad.execute(request) as? NSBatchUpdateResult else {
                context.transactionAuthor = nil
                throw CoreDataError.fetchedObjectFailedToCastToExpectedType
            }
            context.transactionAuthor = nil
            return result
        }
    }

    /// Update the store with a batch of unmanaged models.
    ///
    /// This operation is non-atomic. Each instance may succeed or fail individually.
    @inlinable
    public func update<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> (success: [Model], failed: [CoreDataBatchError<Model>]) {
        var successes = [Model]()
        var failures = [CoreDataBatchError<Model>]()
        await withTaskGroup(of: Result<Model, CoreDataBatchError<Model>>.self, body: { [weak self] group in
            guard let self else {
                group.cancelAll()
                return
            }
            for item in items {
                let added = group.addTaskUnlessCancelled {
                    guard let url = item.managedIdUrl else {
                        return .failure(CoreDataBatchError(item: item, error: .noUrlOnItemToMapToObjectId))
                    }
                    async let result: Result<Model, CoreDataError> = self
                        .update(url, with: item, transactionAuthor: transactionAuthor)
                    switch await result {
                    case let .success(created):
                        return .success(created)
                    case let .failure(error):
                        return .failure(CoreDataBatchError(item: item, error: error))
                    }
                }
                if !added {
                    return
                }
            }
            for await result in group {
                switch result {
                case let .success(success):
                    successes.append(success)
                case let .failure(failure):
                    failures.append(failure)
                }
            }
        })
        return (success: successes, failed: failures)
    }

    /// Update the store with a batch of unmanaged models.
    @inlinable
    public func updateAtomically<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> Result<[Model], CoreDataError> {
        await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            let objects = try items.map { item in
                guard let url = item.managedIdUrl else {
                    throw CoreDataError.noUrlOnItemToMapToObjectId
                }
                let id = try scratchPad.objectId(from: url).get()
                let object = try scratchPad.notDeletedObject(for: id)
                let managed: Model.ManagedModel = try object.asManagedModel()
                try item.updating(managed: managed)
                return managed
            }
            try scratchPad.save()
            try context.performAndWait {
                context.transactionAuthor = transactionAuthor
                try context.save()
                context.transactionAuthor = nil
            }
            return try objects.map(Model.init(managed:))
        }
    }

    /// Execute a NSBatchDeleteRequest against the store.
    @inlinable
    public func delete(
        _ request: NSBatchDeleteRequest,
        transactionAuthor: String? = nil
    ) async -> Result<NSBatchDeleteResult, CoreDataError> {
        await context.performInScratchPad { [context] scratchPad in
            context.transactionAuthor = transactionAuthor
            guard let result = try scratchPad.execute(request) as? NSBatchDeleteResult else {
                context.transactionAuthor = nil
                throw CoreDataError.fetchedObjectFailedToCastToExpectedType
            }
            context.transactionAuthor = nil
            return result
        }
    }

    /// Delete from the store with a batch of unmanaged models.
    ///
    /// This operation is non-atomic. Each instance may succeed or fail individually.
    @inlinable
    public func delete(
        urls: [URL],
        transactionAuthor: String? = nil
    ) async -> (success: [URL], failed: [CoreDataBatchError<URL>]) {
        var successes = [URL]()
        var failures = [CoreDataBatchError<URL>]()
        await withTaskGroup(of: Result<URL, CoreDataBatchError<URL>>.self, body: { [weak self] group in
            guard let self else {
                group.cancelAll()
                return
            }
            for url in urls {
                let added = group.addTaskUnlessCancelled {
                    async let result: Result<Void, CoreDataError> = self
                        .delete(url, transactionAuthor: transactionAuthor)
                    switch await result {
                    case .success:
                        return .success(url)
                    case let .failure(error):
                        return .failure(CoreDataBatchError(item: url, error: error))
                    }
                }
                if !added {
                    return
                }
            }
            for await result in group {
                switch result {
                case let .success(success):
                    successes.append(success)
                case let .failure(failure):
                    failures.append(failure)
                }
            }
        })
        return (success: successes, failed: failures)
    }

    /// Delete from the store with a batch of unmanaged models.
    @inlinable
    public func deleteAtomically(
        urls: [URL],
        transactionAuthor: String? = nil
    ) async -> Result<Void, CoreDataError> {
        await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            for url in urls {
                let id = try scratchPad.objectId(from: url).get()
                let object = try scratchPad.notDeletedObject(for: id)
                object.prepareForDeletion()
                scratchPad.delete(object)
            }
            try scratchPad.save()
            try context.performAndWait {
                context.transactionAuthor = transactionAuthor
                try context.save()
                context.transactionAuthor = nil
            }
            return ()
        }
    }
}
