// CoreDataRepository+Batch.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

extension CoreDataRepository {
    /// Execute a NSBatchInsertRequest against the store.
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

    /// Read a batch of unmanaged models.
    ///
    /// This operation is non-atomic. Each instance may succeed or fail individually.
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

    /// Execute a NSBatchUpdateRequest against the store.
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

    /// Execute a NSBatchDeleteRequest against the store.
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
}
