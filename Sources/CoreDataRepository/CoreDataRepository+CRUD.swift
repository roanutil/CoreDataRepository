// CoreDataRepository+CRUD.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import Combine
import CoreData

extension CoreDataRepository {
    // MARK: Private Functions

    private static func getObject<T: RepositoryManagedModel>(
        fromUrl url: URL,
        context: NSManagedObjectContext,
        method: CRUDRepositoryFailure.Method
    ) throws -> T {
        guard let objectId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
              let object: T = try? context.existingObject(with: objectId) as? T, !object.isDeleted
        else {
            throw CRUDRepositoryFailure(
                code: .noExistingObjectByID,
                method: method,
                url: url
            )
        }
        return object
    }

    // MARK: Functions/Endpoints

    /// Create an instance of a NSManagedObject sub class from a corresponding value type.
    /// Supports specifying a transactionAuthor that is applied to the context before saving.
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     -   _ item: Model
    ///     - transactionAuthor: String = ""
    /// - Returns
    ///     - AnyPublisher<Success<Model>.create(Model), Error>
    ///
    public func create<Model: UnmanagedModel>(
        _ item: Model,
        transactionAuthor: String = ""
    ) -> AnyPublisher<Model, Error> {
        Deferred { [context] in Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                let object = Model.RepoManaged(context: scratchPad)
                object.create(from: item)
                try scratchPad.save()
                if let parentContext = context.parent {
                    try parentContext.save()
                }
                promise(.success(item))
            }
        }}.eraseToAnyPublisher()
    }

    /// Read an instance of a NSManagedObject sub class as a corresponding value type
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     -   _ objectID: NSManagedObjectID
    /// - Returns
    ///     - AnyPublisher<Success<Model>.read(Model), Error>
    ///
    public func read<Model: UnmanagedModel>(_ url: URL) -> AnyPublisher<Model, Error> {
        Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                let object: Model.RepoManaged = try Self.getObject(fromUrl: url, context: scratchPad, method: .read)
                promise(.success(object.asUnmanaged))
            }
        }.eraseToAnyPublisher()
    }

    /// Update an instance of a NSManagedObject sub class from a corresponding value type.
    /// Supports specifying a transactionAuthor that is applied to the context before saving.
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     - objectID: NSManagedObjectID
    ///     - with  item: Model
    ///     - transactionAuthor: String = ""
    /// - Returns
    ///     - AnyPublisher<Success<Model>.update(Model), Error>
    ///
    public func update<Model: UnmanagedModel>(
        _ url: URL,
        with item: Model,
        transactionAuthor: String = ""
    ) -> AnyPublisher<Model, Error> {
        Deferred { [context] in Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                let object: Model.RepoManaged = try Self.getObject(fromUrl: url, context: scratchPad, method: .update)
                object.update(from: item)
                try scratchPad.save()
                promise(.success(item))
            }
        }}.eraseToAnyPublisher()
    }

    /// Delete an instance of a NSManagedObject sub class. Supports specifying a
    /// transactionAuthor that is applied to the context before saving.
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     - objectID: NSManagedObjectID
    ///     - transactionAuthor: String = ""
    /// - Returns
    ///     - AnyPublisher<Void, Error>
    ///
    public func delete(
        _ url: URL,
        transactionAuthor: String = ""
    ) -> AnyPublisher<Void, Error> {
        Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                // Check to see if the object has been deleted. It's possible/likely that an
                // instance of the object's NSManagedObjectID has been kept
                // so it could successfully find the object but it won't be valid.
                guard let objectId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
                      let object: NSManagedObject = try? scratchPad.existingObject(with: objectId),
                      !object.isDeleted
                else {
                    return promise(.failure(CRUDRepositoryFailure(
                        code: .noExistingObjectByID,
                        method: .delete,
                        url: url
                    )))
                }
                object.prepareForDeletion()
                scratchPad.delete(object)
                try scratchPad.save()
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    /// Subscribe to updates for an instance of a NSManagedObject subclass.
    /// - Parameter publisher: Pub<Model, Error>
    /// - Returns: AnyPublisher<Model, Error>
    public func readSubscription<Model: UnmanagedModel>(_ url: URL) -> AnyPublisher<Model, Error> {
        let publisher: AnyPublisher<Model, Error> = read(url)
        return AnyPublisher.create { [context] subscriber in
            let subject = PassthroughSubject<Model, Error>()
            subject.sink(receiveCompletion: subscriber.send, receiveValue: subscriber.send)
                .store(in: &self.cancellables)
            let id = UUID()
            var subscription: SubscriptionProvider?
            publisher.sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        subject.send(completion: completion)
                    }
                },
                receiveValue: { value in
                    var object: Model.RepoManaged?
                    guard let url = value.managedRepoUrl else {
                        subject
                            .send(completion: .failure(CRUDRepositoryFailure(
                                code: .unknown,
                                method: .read,
                                url: nil
                            )))
                        return
                    }
                    self.context.performAndWait { () in
                        do {
                            let _object: Model.RepoManaged = try Self.getObject(
                                fromUrl: url,
                                context: context,
                                method: .read
                            )
                            object = _object
                        } catch {
                            subject.send(completion: .failure(error))
                        }
                    }
                    guard let readObject = object else {
                        subject
                            .send(completion: .failure(CRUDRepositoryFailure(code: .unknown, method: .read, url: url)))
                        return
                    }
                    let subscriptionProvider = ReadSubscription(id: id, object: readObject, subject: subject)
                    subscription = subscriptionProvider
                    subscriptionProvider.start()
                    self.subscriptions.append(subscriptionProvider)
                    subject.send(value)
                }
            ).store(in: &self.cancellables)
            return AnyCancellable {
                subscription?.cancel()
                self.subscriptions.removeAll(where: { $0.id == id as AnyHashable })
            }
        }
    }
}
