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
    ///     - AnyPublisher<Success, Error>
    public func insert(
        _ request: NSBatchInsertRequest,
        transactionAuthor: String = ""
    ) -> AnyPublisher<NSBatchInsertResult, Error> {
        Deferred { [context] in Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                do {
                    if let result = try scratchPad.execute(request) as? NSBatchInsertResult {
                        promise(.success(result))
                    }
                } catch {
                    promise(.failure(error))
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
        transactionAuthor: String = ""
    )
        -> AnyPublisher<(success: [Model], failed: [Model]), Never>
    {
        Publishers.MergeMany<AnyPublisher<_Result<Model, Model>, Never>>(
            items.map { item -> AnyPublisher<_Result<Model, Model>, Never> in
                let createPub: AnyPublisher<Model, Error> = create(item, transactionAuthor: transactionAuthor)
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
    ///     - _ items: [Model]
    /// - Returns
    ///     - AnyPublisher<(success: [Model, failed: [Model]), Never>
    public func read<Model: UnmanagedModel>(urls: [URL]) -> AnyPublisher<(success: [Model], failed: [URL]), Never> {
        Publishers.MergeMany<AnyPublisher<_Result<Model, URL>, Never>>(
            urls.map { url -> AnyPublisher<_Result<Model, URL>, Never> in
                let readPub: AnyPublisher<Model, Error> = read(url)
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
    ///     - AnyPublisher<Success, Error>
    public func update(
        _ request: NSBatchUpdateRequest,
        transactionAuthor: String = ""
    ) -> AnyPublisher<NSBatchUpdateResult, Error> {
        Deferred { [context] in Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                do {
                    if let result = try scratchPad.execute(request) as? NSBatchUpdateResult {
                        promise(.success(result))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }}.eraseToAnyPublisher()
    }

    /// Wrapper for success/failure output where failure does not confrom to `Error`
    private enum _Result<Success, Failure> {
        case success(Success)
        case failure(Failure)
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - _ items: [Model]
    ///     - transactionAuthor: String
    /// - Returns
    ///     - AnyPublisher<(success: [Model, failed: [Model]), Never>
    public func update<Model: UnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String = ""
    )
        -> AnyPublisher<(success: [Model], failed: [Model]), Never>
    {
        Publishers.MergeMany<AnyPublisher<_Result<Model, Model>, Never>>(
            items.map { item -> AnyPublisher<_Result<Model, Model>, Never> in
                guard let url = item.managedRepoUrl else {
                    return Just(_Result<Model, Model>.failure(item))
                        .eraseToAnyPublisher()
                }
                let updatePub: AnyPublisher<Model, Error> = update(
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
    ///     - AnyPublisher<Success, Error>
    public func delete(
        _ request: NSBatchDeleteRequest,
        transactionAuthor: String = ""
    ) -> AnyPublisher<NSBatchDeleteResult, Error> {
        Deferred { [context] in Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                do {
                    if let result = try scratchPad.execute(request) as? NSBatchDeleteResult {
                        promise(.success(result))
                    }
                } catch {
                    promise(.failure(error))
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
        transactionAuthor: String = ""
    ) -> AnyPublisher<(success: [URL], failed: [URL]), Never> {
        Publishers.MergeMany<AnyPublisher<_Result<URL, URL>, Never>>(
            urls.map { url -> AnyPublisher<_Result<URL, URL>, Never> in
                let deletePub: AnyPublisher<Void, Error> = delete(url, transactionAuthor: transactionAuthor)
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
