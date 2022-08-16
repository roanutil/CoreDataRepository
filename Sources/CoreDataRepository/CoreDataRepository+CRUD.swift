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
    // MARK: Functions/Endpoints

    /// Create an instance of a NSManagedObject sub class from a corresponding value type.
    /// Supports specifying a transactionAuthor that is applied to the context before saving.
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     -   _ item: Model
    ///     - transactionAuthor: String? = nil
    /// - Returns
    ///     - AnyPublisher<Model, CoreDataRepositoryError>
    ///
    public func create<Model: UnmanagedModel>(
        _ item: Model,
        transactionAuthor: String? = nil
    ) -> AnyPublisher<Model, CoreDataRepositoryError> {
        Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                let object = Model.RepoManaged(context: scratchPad)
                object.create(from: item)
                let result: Result<NSManagedObject, CoreDataRepositoryError> = .success(object)
                return result
                    .map(to: Model.RepoManaged.self, context: scratchPad)
                    .save(context: scratchPad)
                    .map(\.asUnmanaged)
            }
        }.eraseToAnyPublisher()
    }

    /// Read an instance of a NSManagedObject sub class as a corresponding value type
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     -   _ objectID: NSManagedObjectID
    /// - Returns
    ///     - AnyPublisher<Model, CoreDataRepositoryError>
    ///
    public func read<Model: UnmanagedModel>(_ url: URL) -> AnyPublisher<Model, CoreDataRepositoryError> {
        let readContext = context.childContext()
        return Future { promise in
            readContext.perform {
                promise(
                    Self.getObjectId(fromUrl: url, context: readContext)
                        .mapToNSManagedObject(context: readContext)
                        .map(to: Model.RepoManaged.self, context: readContext)
                        .map(\.asUnmanaged)
                )
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
    ///     - transactionAuthor: String? = nil
    /// - Returns
    ///     - AnyPublisher<Model, CoreDataRepositoryError>
    ///
    public func update<Model: UnmanagedModel>(
        _ url: URL,
        with item: Model,
        transactionAuthor: String? = nil
    ) -> AnyPublisher<Model, CoreDataRepositoryError> {
        Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                return Self.getObjectId(fromUrl: url, context: scratchPad)
                    .mapToNSManagedObject(context: scratchPad)
                    .map(to: Model.RepoManaged.self, context: scratchPad)
                    .map { repoManaged -> Model.RepoManaged in
                        repoManaged.update(from: item)
                        return repoManaged
                    }
                    .save(context: scratchPad)
                    .map(\.asUnmanaged)
            }
        }.eraseToAnyPublisher()
    }

    /// Delete an instance of a NSManagedObject sub class. Supports specifying a
    /// transactionAuthor that is applied to the context before saving.
    /// - Types
    ///     - Model: UnmanagedModel
    /// - Parameters
    ///     - objectID: NSManagedObjectID
    ///     - transactionAuthor: String? = nil
    /// - Returns
    ///     - AnyPublisher<Void, CoreDataRepositoryError>
    ///
    public func delete(
        _ url: URL,
        transactionAuthor: String? = nil
    ) -> AnyPublisher<Void, CoreDataRepositoryError> {
        Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                scratchPad.transactionAuthor = transactionAuthor
                return Self.getObjectId(fromUrl: url, context: scratchPad)
                    .mapToNSManagedObject(context: scratchPad)
                    .map { repoManaged in
                        repoManaged.prepareForDeletion()
                        scratchPad.delete(repoManaged)
                        return ()
                    }
                    .save(context: scratchPad)
            }
        }.eraseToAnyPublisher()
    }

    /// Subscribe to updates for an instance of a NSManagedObject subclass.
    /// - Parameter publisher: Pub<Model, Error>
    /// - Returns: AnyPublisher<Model, CoreDataRepositoryError>
    public func readSubscription<Model: UnmanagedModel>(_ url: URL) -> AnyPublisher<Model, CoreDataRepositoryError> {
        let readContext = context.childContext()
        let readPublisher: AnyPublisher<Model.RepoManaged, CoreDataRepositoryError> = readRepoManaged(
            url,
            readContext: readContext
        )
        var subjectCancellable: AnyCancellable?
        return Publishers.Create<Model, CoreDataRepositoryError> { [weak self] subscriber in
            let subject = PassthroughSubject<Model, CoreDataRepositoryError>()
            subjectCancellable = subject.sink(receiveCompletion: subscriber.send, receiveValue: subscriber.send)

            let id = UUID()
            var subscription: SubscriptionProvider?
            self?.cancellables.insert(readPublisher.sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        subject.send(completion: completion)
                    }
                },
                receiveValue: { repoManaged in
                    let subscriptionProvider = ReadSubscription(
                        id: id,
                        objectId: repoManaged.objectID,
                        context: readContext,
                        subject: subject
                    )
                    subscription = subscriptionProvider
                    subscriptionProvider.start()
                    if let _self = self,
                       let _subjectCancellable = subjectCancellable
                    {
                        _self.subscriptions.append(subscriptionProvider)
                        _self.cancellables.insert(_subjectCancellable)
                    } else {
                        subjectCancellable?.cancel()
                        subscription?.cancel()
                    }
                    subscriptionProvider.manualFetch()
                }
            ))
            return AnyCancellable {
                subscription?.cancel()
                self?.subscriptions.removeAll(where: { $0.id == id as AnyHashable })
            }
        }.eraseToAnyPublisher()
    }

    // MARK: Private Functions

    private static func getObjectId(
        fromUrl url: URL,
        context: NSManagedObjectContext
    ) -> Result<NSManagedObjectID, CoreDataRepositoryError> {
        guard let objectId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
            return Result.failure(.failedToGetObjectIdFromUrl(url))
        }
        return .success(objectId)
    }

    private func readRepoManaged<T>(
        _ url: URL,
        readContext: NSManagedObjectContext
    ) -> AnyPublisher<T, CoreDataRepositoryError>
        where T: RepositoryManagedModel
    {
        Future { promise in
            readContext.performAndWait {
                let result = Self.getObjectId(fromUrl: url, context: readContext)
                    .mapToNSManagedObject(context: readContext)
                    .map(to: T.self)
                promise(result)
            }
        }.eraseToAnyPublisher()
    }
}
