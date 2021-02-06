//
//  CRUDRepository.swift
//
//  Created by Andrew Roan on 1/15/21.
//

import CoreData
import Combine

/// A CoreData repository with typical create, read, update, and delete endpoints
public final class CRUDRepository {
    // MARK: Properties
    /// CoreData context the repository uses
    public let context: NSManagedObjectContext

    // MARK: Init
    /// Initializes a CRUDRepository
    /// - Parameters
    ///     - context: NSManagedObjectContext
    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: Return Types
    /// Return type for successful completion of action for an endpoint
    public enum Success<Model: UnmanagedModel> {
        case create(Model)
        case read(Model)
        case update(Model)
        case delete(NSManagedObjectID)
    }

    /// Return tpe for failure of an endpoint action
    public enum Failure<Model: UnmanagedModel>: Error {
        case create(Model, RepositoryErrors)
        case read(NSManagedObjectID, RepositoryErrors)
        case update(Model, RepositoryErrors)
        case delete(NSManagedObjectID, RepositoryErrors)
    }

    // MARK: Functions/Endpoints
    /// Create an instance of a NSManagedObject sub class from a corresponding value type. Supports specifying a transactionAuthor that is applied to the context before saving.
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     -   _ item: Model
    ///     - transactionAuthor: String = ""
    /// - Returns
    ///     - AnyPublisher<Success<Model>.create(Model), Failure<Model>.create(Model, RepositoryErrors)>
    ///
    public func create<Model: UnmanagedModel>(_ item: Model, transactionAuthor: String = "") -> AnyPublisher<Success<Model>, Failure<Model>> {
        Future { [weak self] callback in
            guard let self = self else { return callback(.failure(.create(item, .unknown))) }
            self.context.perform {
                let object = Model.RepoManaged(context: self.context)
                object.update(from: item)
                do {
                    self.context.transactionAuthor = transactionAuthor
                    try self.context.save()
                    callback(.success(.create(item)))
                } catch {
                    callback(.failure(.create(item, .cocoa(error as NSError))))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// Read an instance of a NSManagedObject sub class as a corresponding value type
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     -   _ objectID: NSManagedObjectID
    /// - Returns
    ///     - AnyPublisher<Success<Model>.read(Model), Failure<Model>.read(NSManagedObjectID, RepositoryErrors)>
    ///
    public func read<Model: UnmanagedModel>(_ objectID: NSManagedObjectID) -> AnyPublisher<Success<Model>, Failure<Model>> {
        Future { [weak self] callback in
            guard let self = self else { return callback(.failure(.read(objectID, .unknown))) }
            self.context.performAndWait { () -> Void in
                do {
                    // Check to see if the object has been deleted. It's possible/likely that an instance of the object's NSManagedObjectID has been kept
                    // so it could successfully find the object but it won't be valid.
                    guard let object = try self.context.existingObject(with: objectID) as? Model.RepoManaged, !object.isDeleted else {
                        return callback(.failure(.read(objectID, .noExistingObjectByID)))
                    }
                    callback(.success(.read(object.asUnmanaged)))
                } catch {
                    callback(.failure(.read(objectID, .cocoa(error as NSError))))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// Update an instance of a NSManagedObject sub class from a corresponding value type. Supports specifying a transactionAuthor that is applied to the context before saving.
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     - objectID: NSManagedObjectID
    ///     - with  item: Model
    ///     - transactionAuthor: String = ""
    /// - Returns
    ///     - AnyPublisher<Success<Model>.update(Model), Failure<Model>.update(Model, RepositoryErrors)>
    ///
    public func update<Model: UnmanagedModel>(
        _ objectID: NSManagedObjectID,
        with item: Model,
        transactionAuthor: String = ""
    ) -> AnyPublisher<Success<Model>, Failure<Model>> {
        Future { [weak self] callback in
            guard let self = self else { return callback(.failure(.update(item, .unknown))) }
            self.context.perform {
                // Check to see if the object has been deleted. It's possible/likely that an instance of the object's NSManagedObjectID has been kept
                // so it could successfully find the object but it won't be valid.
                guard let object: Model.RepoManaged = try? self.context.existingObject(with: objectID) as? Model.RepoManaged, !object.isDeleted else {
                    return callback(.failure(.update(item, .noExistingObjectByID)))
                }
                object.update(from: item)
                do {
                    self.context.transactionAuthor = transactionAuthor
                    try self.context.save()
                    callback(.success(.update(item)))
                } catch {
                    callback(.failure(.update(item, .cocoa(error as NSError))))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// Delete an instance of a NSManagedObject sub class. Supports specifying a transactionAuthor that is applied to the context before saving.
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     - objectID: NSManagedObjectID
    ///     - transactionAuthor: String = ""
    /// - Returns
    ///     - AnyPublisher<Success<Model>.delete(Model), Failure<Model>.delete(Model, RepositoryErrors)>
    ///
    public func delete<Model: UnmanagedModel>(_ objectID: NSManagedObjectID, transactionAuthor: String = "") -> AnyPublisher<Success<Model>, Failure<Model>> {
        Future { [weak self] callback in
            guard let self = self else { return callback(.failure(.delete(objectID, .unknown))) }
            self.context.performAndWait {
                do {
                    // Check to see if the object has been deleted. It's possible/likely that an instance of the object's NSManagedObjectID has been kept
                    // so it could successfully find the object but it won't be valid.
                    guard let object: Model.RepoManaged = try? self.context.existingObject(with: objectID) as? Model.RepoManaged, !object.isDeleted else { return callback(.failure(.delete(objectID, .noExistingObjectByID))) }
                    object.prepareForDeletion()
                    self.context.delete(object)
                    self.context.transactionAuthor = transactionAuthor
                    try self.context.save()
                    callback(.success(.delete(objectID)))
                } catch {
                    callback(.failure(.delete(objectID, .cocoa(error as NSError))))
                }
            }
        }.eraseToAnyPublisher()
    }
}

extension CRUDRepository.Success: Equatable where Model: Equatable {}
extension CRUDRepository.Failure: Equatable where Model: Equatable {}

extension CRUDRepository.Success: Hashable where Model: Hashable {}
extension CRUDRepository.Failure: Hashable where Model: Hashable {}
