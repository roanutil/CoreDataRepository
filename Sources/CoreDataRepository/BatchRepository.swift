//
//  BatchRepository.swift
//
//  Created by Andrew Roan on 1/16/21.
//

import CoreData
import Combine

/// A CoreData repository that supports background batch operations
public final class BatchRepository {
    // MARK: Properties
    // should always be a background context
    /// The context used by the repository
    public let context: NSManagedObjectContext

    // MARK: Init
    /// Initializes an instance of the repository
    /// - Parameters
    ///     - context: NSManagedObjectContext
    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: Return Types
    /// Return type for successful results
    public enum Success: Error, Equatable {
        case insert(NSBatchInsertRequest, NSBatchInsertResult)
        case update(NSBatchUpdateRequest, NSBatchUpdateResult)
        case delete(NSBatchDeleteRequest, NSBatchDeleteResult)
    }

    /// Return type for failures
    public enum Failure: Error, Equatable {
        case insert(NSBatchInsertRequest, RepositoryErrors)
        case update(NSBatchUpdateRequest, RepositoryErrors)
        case delete(NSBatchDeleteRequest, RepositoryErrors)
    }

    // MARK: Functions
    /// Batch insert objects into CoreData
    /// - Parameters
    ///     - _ request: NSBatchInsertRequest
    /// - Returns
    ///     - AnyPublisher<Success, Failure>
    public func insert(_ request: NSBatchInsertRequest) -> AnyPublisher<Success, Failure> {
        Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(.insert(request, .unknown))) }
            self.context.performAndWait { [weak self] in
                guard let self = self else { return callback(.failure(.insert(request, .unknown))) }
                do {
                    if let result = try self.context.execute(request) as? NSBatchInsertResult {
                        callback(.success(.insert(request, result)))
                    }
                } catch {
                    callback(.failure(.insert(request, .cocoa(error as NSError))))
                }
            }
        }}.eraseToAnyPublisher()
    }

    /// Batch update objects in CoreData
    /// - Parameters
    ///     - _ request: NSBatchInsertRequest
    /// - Returns
    ///     - AnyPublisher<Success, Failure>
    public func update(_ request: NSBatchUpdateRequest) -> AnyPublisher<Success, Failure> {
        Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(.update(request, .unknown))) }
            self.context.performAndWait { [weak self] in
                guard let self = self else { return callback(.failure(.update(request, .unknown))) }
                do {
                    if let result = try self.context.execute(request) as? NSBatchUpdateResult {
                        callback(.success(.update(request, result)))
                    }
                } catch {
                    callback(.failure(.update(request, .cocoa(error as NSError))))
                }
            }
        }}.eraseToAnyPublisher()
    }

    /// Batch delete objects from CoreData
    /// - Parameters
    ///     - _ request: NSBatchInsertRequest
    /// - Returns
    ///     - AnyPublisher<Success, Failure>
    public func delete(_ request: NSBatchDeleteRequest) -> AnyPublisher<Success, Failure> {
        Deferred { Future { [weak self] callback in
            guard let self = self else { return callback(.failure(.delete(request, .unknown))) }
            self.context.performAndWait { [weak self] in
                guard let self = self else { return callback(.failure(.delete(request, .unknown))) }
                do {
                    if let result = try self.context.execute(request) as? NSBatchDeleteResult {
                        callback(.success(.delete(request, result)))
                    }
                } catch {
                    callback(.failure(.delete(request, .cocoa(error as NSError))))
                }
            }
        }}.eraseToAnyPublisher()
    }
}
