// CoreDataRepository+Batch.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import Combine
import CoreData

extension CoreDataRepository {
    // MARK: Functions

    /// Batch insert objects into CoreData
    /// - Parameters
    ///     - _ request: NSBatchInsertRequest
    ///     - transactionAuthor: String
    /// - Returns
    ///     - AnyPublisher<NSBatchInsertResult, CoreDataRepositoryError>
    public func insert(
        _ request: NSBatchInsertRequest,
        transactionAuthor: String? = nil
    ) -> AnyPublisher<NSBatchInsertResult, CoreDataRepositoryError> {
        Deferred { [context] in Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                do {
                    if let result = try scratchPad.execute(request) as? NSBatchInsertResult {
                        return .success(result)
                    } else {
                        return .failure(.fetchedObjectFailedToCastToExpectedType)
                    }
                } catch {
                    return .failure(.coreData(error as NSError))
                }
            }
        }}.eraseToAnyPublisher()
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - _ items: [Model]
    ///     - transactionAuthor: String
    /// - Returns
    ///     - AnyPublisher<(success: [Model, failed: [Model]), Never>
    public func create<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    )
        -> AnyPublisher<(success: [Model], failed: [Model]), Never>
    {
        Publishers.MergeMany<AnyPublisher<_Result<Model, Model>, Never>>(
            items.map { item -> AnyPublisher<_Result<Model, Model>, Never> in
                let createPub: AnyPublisher<Model, CoreDataRepositoryError> = create(
                    item,
                    transactionAuthor: transactionAuthor
                )
                return createPub
                    .map(_Result<Model, Model>.success)
                    .catch { _ in
                        Just(_Result<Model, Model>.failure(item))
                    }
                    .eraseToAnyPublisher()
            }
        )
        .reduce((success: [], failed: [])) { _output, result in
            var output = _output
            switch result {
            case let .success(item):
                var successes = output.success
                successes.append(item)
                output.success = successes
            case let .failure(failure):
                var failures = output.failed
                failures.append(failure)
                output.failed = failures
            }
            return output
        }
        .eraseToAnyPublisher()
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - urls: [URL]
    /// - Returns
    ///     - AnyPublisher<(success: [Model, failed: [Model]), Never>
    public func read<Model: UnmanagedModel>(urls: [URL]) -> AnyPublisher<(success: [Model], failed: [URL]), Never> {
        Publishers.MergeMany<AnyPublisher<_Result<Model, URL>, Never>>(
            urls.map { url -> AnyPublisher<_Result<Model, URL>, Never> in
                let readPub: AnyPublisher<Model, CoreDataRepositoryError> = read(url)
                return readPub
                    .map(_Result<Model, URL>.success)
                    .catch { _ in
                        Just(_Result<Model, URL>.failure(url))
                    }
                    .eraseToAnyPublisher()
            }
        )
        .reduce((success: [], failed: [])) { _output, result in
            var output = _output
            switch result {
            case let .success(item):
                var successes = output.success
                successes.append(item)
                output.success = successes
            case let .failure(failure):
                var failures = output.failed
                failures.append(failure)
                output.failed = failures
            }
            return output
        }
        .eraseToAnyPublisher()
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - _ request: NSBatchInsertRequest
    ///     - transactionAuthor: String
    /// - Returns
    ///     - AnyPublisher<NSBatchUpdateResult, CoreDataRepositoryError>
    public func update(
        _ request: NSBatchUpdateRequest,
        transactionAuthor: String? = nil
    ) -> AnyPublisher<NSBatchUpdateResult, CoreDataRepositoryError> {
        Deferred { [context] in Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                do {
                    if let result = try scratchPad.execute(request) as? NSBatchUpdateResult {
                        return .success(result)
                    } else {
                        return .failure(.fetchedObjectFailedToCastToExpectedType)
                    }
                } catch {
                    return .failure(.coreData(error as NSError))
                }
            }
        }}.eraseToAnyPublisher()
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - _ items: [Model]
    ///     - transactionAuthor: String
    /// - Returns
    ///     - AnyPublisher<(success: [Model, failed: [Model]), Never>
    public func update<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    )
        -> AnyPublisher<(success: [Model], failed: [Model]), Never>
    {
        Publishers.MergeMany<AnyPublisher<_Result<Model, Model>, Never>>(
            items.map { item -> AnyPublisher<_Result<Model, Model>, Never> in
                guard let url = item.managedRepoUrl else {
                    return Just(_Result<Model, Model>.failure(item))
                        .eraseToAnyPublisher()
                }
                let updatePub: AnyPublisher<Model, CoreDataRepositoryError> = update(
                    url,
                    with: item,
                    transactionAuthor: transactionAuthor
                )
                return updatePub
                    .map(_Result<Model, Model>.success)
                    .catch { _ in
                        Just(_Result<Model, Model>.failure(item))
                    }
                    .eraseToAnyPublisher()
            }
        )
        .collect(items.count)
        .map { updatedItems -> (success: [Model], failed: [Model]) in
            updatedItems.reduce((success: [], failed: [])) { _output, result in
                var output = _output
                switch result {
                case let .success(item):
                    var successes = output.success
                    successes.append(item)
                    output.success = successes
                case let .failure(failure):
                    var failures = output.failed
                    failures.append(failure)
                    output.failed = failures
                }
                return output
            }
        }

        .eraseToAnyPublisher()
    }

    /// Batch delete objects from CoreData
    /// - Parameters
    ///     - _ request: NSBatchInsertRequest
    ///     - transactionAuthor: String
    /// - Returns
    ///     - AnyPublisher<NSBatchDeleteResult, CoreDataRepositoryError>
    public func delete(
        _ request: NSBatchDeleteRequest,
        transactionAuthor: String? = nil
    ) -> AnyPublisher<NSBatchDeleteResult, CoreDataRepositoryError> {
        Deferred { [context] in Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                do {
                    if let result = try scratchPad.execute(request) as? NSBatchDeleteResult {
                        return .success(result)
                    } else {
                        return .failure(.fetchedObjectFailedToCastToExpectedType)
                    }
                } catch {
                    return .failure(.coreData(error as NSError))
                }
            }
        }}.eraseToAnyPublisher()
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - _ items: [Model]
    /// - Returns
    ///     - AnyPublisher<(success: [Model, failed: [Model]), Never>
    public func delete(
        urls: [URL],
        transactionAuthor: String? = nil
    ) -> AnyPublisher<(success: [URL], failed: [URL]), Never> {
        Publishers.MergeMany<AnyPublisher<_Result<URL, URL>, Never>>(
            urls.map { url -> AnyPublisher<_Result<URL, URL>, Never> in
                let deletePub: AnyPublisher<Void, CoreDataRepositoryError> = delete(
                    url,
                    transactionAuthor: transactionAuthor
                )
                return deletePub
                    .map { _ in .success(url) }
                    .catch { _ in
                        Just(_Result<URL, URL>.failure(url))
                    }
                    .eraseToAnyPublisher()
            }
        )
        .reduce((success: [], failed: [])) { _output, result in
            var output = _output
            switch result {
            case let .success(item):
                var successes = output.success
                successes.append(item)
                output.success = successes
            case let .failure(failure):
                var failures = output.failed
                failures.append(failure)
                output.failed = failures
            }
            return output
        }
        .eraseToAnyPublisher()
    }
}
