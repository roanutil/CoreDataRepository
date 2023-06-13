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

    public func create<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> (success: [Model], failed: [Model]) {
        var successes = [Model]()
        var failures = [Model]()
        await withTaskGroup(of: Either<Model, Model>.self, body: { [weak self] group in
            guard let self = self else {
                group.cancelAll()
                return
            }
            for item in items {
                let added = group.addTaskUnlessCancelled {
                    async let result: Result<Model, CoreDataError> = self
                        .create(item, transactionAuthor: transactionAuthor)
                    switch await result {
                    case let .success(created):
                        return Either<Model, Model>.success(created)
                    case .failure:
                        return Either<Model, Model>.failure(item)
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

    public func read<Model: UnmanagedModel>(urls: [URL], as _: Model.Type) async -> (success: [Model], failed: [URL]) {
        var successes = [Model]()
        var failures = [URL]()
        await withTaskGroup(of: Either<Model, URL>.self, body: { [weak self] group in
            guard let self = self else {
                group.cancelAll()
                return
            }
            for url in urls {
                let added = group.addTaskUnlessCancelled {
                    async let result = self.read(url, of: Model.self)
                    switch await result {
                    case let .success(created):
                        return Either<Model, URL>.success(created)
                    case .failure:
                        return Either<Model, URL>.failure(url)
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

    public func update<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> (success: [Model], failed: [Model]) {
        var successes = [Model]()
        var failures = [Model]()
        await withTaskGroup(of: Either<Model, Model>.self, body: { [weak self] group in
            guard let self = self else {
                group.cancelAll()
                return
            }
            for item in items {
                let added = group.addTaskUnlessCancelled {
                    guard let url = item.managedRepoUrl else {
                        return Either<Model, Model>.failure(item)
                    }
                    async let result: Result<Model, CoreDataError> = self
                        .update(url, with: item, transactionAuthor: transactionAuthor)
                    switch await result {
                    case let .success(created):
                        return Either<Model, Model>.success(created)
                    case .failure:
                        return Either<Model, Model>.failure(item)
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

    public func delete(
        urls: [URL],
        transactionAuthor: String? = nil
    ) async -> (success: [URL], failed: [URL]) {
        var successes = [URL]()
        var failures = [URL]()
        await withTaskGroup(of: Either<URL, URL>.self, body: { [weak self] group in
            guard let self = self else {
                group.cancelAll()
                return
            }
            for url in urls {
                let added = group.addTaskUnlessCancelled {
                    async let result: Result<Void, CoreDataError> = self
                        .delete(url, transactionAuthor: transactionAuthor)
                    switch await result {
                    case .success:
                        return Either<URL, URL>.success(url)
                    case .failure:
                        return Either<URL, URL>.failure(url)
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
