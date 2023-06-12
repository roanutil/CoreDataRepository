// CoreDataRepository+Batch.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CoreData

extension CoreDataRepository {
    // MARK: Functions

    /// Batch insert objects into CoreData
    /// - Parameters
    ///     - _ request: NSBatchInsertRequest
    ///     - transactionAuthor: String
    /// - Returns
    ///     - Result<NSBatchInsertResult, CoreDataRepositoryError>
    public func insert(
        _ request: NSBatchInsertRequest,
        transactionAuthor: String? = nil
    ) async -> Result<NSBatchInsertResult, CoreDataRepositoryError> {
        await context.performInScratchPad { [context] scratchPad in
            context.transactionAuthor = transactionAuthor
            guard let result = try scratchPad.execute(request) as? NSBatchInsertResult else {
                context.transactionAuthor = nil
                throw CoreDataRepositoryError.fetchedObjectFailedToCastToExpectedType
            }
            context.transactionAuthor = nil
            return result
        }
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - _ items: [Model]
    ///     - transactionAuthor: String
    /// - Returns
    ///     - (success: [Model, failed: [Model])
    public func create<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> (success: [Model], failed: [Model]) {
        var successes = [Model]()
        var failures = [Model]()
        await withTaskGroup(of: _Result<Model, Model>.self, body: { [weak self] group in
            guard let self = self else {
                group.cancelAll()
                return
            }
            for item in items {
                let added = group.addTaskUnlessCancelled {
                    async let result: Result<Model, CoreDataRepositoryError> = self
                        .create(item, transactionAuthor: transactionAuthor)
                    switch await result {
                    case let .success(created):
                        return _Result<Model, Model>.success(created)
                    case .failure:
                        return _Result<Model, Model>.failure(item)
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

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - urls: [URL]
    /// - Returns
    ///     - (success: [Model, failed: [Model])
    @available(*, deprecated, message: "This method has an unused parameter for transactionAuthor.")
    public func read<Model: UnmanagedModel>(
        urls: [URL],
        transactionAuthor _: String? = nil
    ) async -> (success: [Model], failed: [URL]) {
        await read(urls: urls)
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - urls: [URL]
    /// - Returns
    ///     - (success: [Model, failed: [Model])
    public func read<Model: UnmanagedModel>(urls: [URL]) async -> (success: [Model], failed: [URL]) {
        var successes = [Model]()
        var failures = [URL]()
        await withTaskGroup(of: _Result<Model, URL>.self, body: { [weak self] group in
            guard let self = self else {
                group.cancelAll()
                return
            }
            for url in urls {
                let added = group.addTaskUnlessCancelled {
                    async let result: Result<Model, CoreDataRepositoryError> = self.read(url)
                    switch await result {
                    case let .success(created):
                        return _Result<Model, URL>.success(created)
                    case .failure:
                        return _Result<Model, URL>.failure(url)
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

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - _ request: NSBatchInsertRequest
    ///     - transactionAuthor: String
    /// - Returns
    ///     - Result<NSBatchUpdateResult, CoreDataRepositoryError>
    public func update(
        _ request: NSBatchUpdateRequest,
        transactionAuthor: String? = nil
    ) async -> Result<NSBatchUpdateResult, CoreDataRepositoryError> {
        await context.performInScratchPad { [context] scratchPad in
            context.transactionAuthor = transactionAuthor
            guard let result = try scratchPad.execute(request) as? NSBatchUpdateResult else {
                context.transactionAuthor = nil
                throw CoreDataRepositoryError.fetchedObjectFailedToCastToExpectedType
            }
            context.transactionAuthor = nil
            return result
        }
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - _ items: [Model]
    ///     - transactionAuthor: String
    /// - Returns
    ///     - (success: [Model, failed: [Model])
    public func update<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> (success: [Model], failed: [Model]) {
        var successes = [Model]()
        var failures = [Model]()
        await withTaskGroup(of: _Result<Model, Model>.self, body: { [weak self] group in
            guard let self = self else {
                group.cancelAll()
                return
            }
            for item in items {
                let added = group.addTaskUnlessCancelled {
                    guard let url = item.managedRepoUrl else {
                        return _Result<Model, Model>.failure(item)
                    }
                    async let result: Result<Model, CoreDataRepositoryError> = self
                        .update(url, with: item, transactionAuthor: transactionAuthor)
                    switch await result {
                    case let .success(created):
                        return _Result<Model, Model>.success(created)
                    case .failure:
                        return _Result<Model, Model>.failure(item)
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

    /// Batch delete objects from CoreData
    /// - Parameters
    ///     - _ request: NSBatchInsertRequest
    ///     - transactionAuthor: String
    /// - Returns
    ///     - Result<NSBatchDeleteResult, CoreDataRepositoryError>
    public func delete(
        _ request: NSBatchDeleteRequest,
        transactionAuthor: String? = nil
    ) async -> Result<NSBatchDeleteResult, CoreDataRepositoryError> {
        await context.performInScratchPad { [context] scratchPad in
            context.transactionAuthor = transactionAuthor
            guard let result = try scratchPad.execute(request) as? NSBatchDeleteResult else {
                context.transactionAuthor = nil
                throw CoreDataRepositoryError.fetchedObjectFailedToCastToExpectedType
            }
            context.transactionAuthor = nil
            return result
        }
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - _ items: [Model]
    /// - Returns
    ///     - (success: [Model, failed: [Model])
    public func delete(
        urls: [URL],
        transactionAuthor: String? = nil
    ) async -> (success: [URL], failed: [URL]) {
        var successes = [URL]()
        var failures = [URL]()
        await withTaskGroup(of: _Result<URL, URL>.self, body: { [weak self] group in
            guard let self = self else {
                group.cancelAll()
                return
            }
            for url in urls {
                let added = group.addTaskUnlessCancelled {
                    async let result: Result<Void, CoreDataRepositoryError> = self
                        .delete(url, transactionAuthor: transactionAuthor)
                    switch await result {
                    case .success:
                        return _Result<URL, URL>.success(url)
                    case .failure:
                        return _Result<URL, URL>.failure(url)
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
