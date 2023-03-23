// CoreDataRepository+Fetch.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CombineExt
import CoreData

extension CoreDataRepository {
    // MARK: Functions/Endpoints

    /// Fetch a single array of value types corresponding to a NSManagedObject sub class.
    /// - Parameters
    ///     - _ request: NSFetchRequest<Model.RepoManaged>
    /// - Returns
    ///     - Result<[Model], CoreDataRepositoryError>
    ///
    public func fetch<Model: UnmanagedModel>(_ request: NSFetchRequest<Model.RepoManaged>) async
        -> Result<[Model], CoreDataRepositoryError>
    {
        await context.performInChild { fetchContext in
            try fetchContext.fetch(request).map(\.asUnmanaged)
        }
    }

    /// Fetch an array of value types corresponding to a NSManagedObject sub class and receive
    /// updates for changes in the context.
    /// - Parameters
    ///     - _request: NSFetchRequest<Model.RepoManaged>
    /// - Returns
    ///     - AnyPublisher<[Model], CoreDataRepositoryError>
    public func fetchSubscription<Model: UnmanagedModel>(_ request: NSFetchRequest<Model.RepoManaged>)
        -> AnyPublisher<[Model], CoreDataRepositoryError>
    {
        let fetchContext = context.childContext()
        let fetchPublisher: AnyPublisher<[Model], CoreDataRepositoryError> = _fetch(request, fetchContext: fetchContext)
        var subjectCancellable: AnyCancellable?
        var fetchCancellable: AnyCancellable?
        return AnyPublisher.create { [weak self] subscriber in
            let subject = PassthroughSubject<[Model], CoreDataRepositoryError>()
            subjectCancellable = subject.sink(receiveCompletion: subscriber.send, receiveValue: subscriber.send)
            let id = UUID()
            var subscription: SubscriptionProvider?
            fetchCancellable = fetchPublisher.sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        subject.send(completion: completion)
                    }
                },
                receiveValue: { value in
                    let subscriptionProvider = FetchSubscription(
                        id: id,
                        request: request,
                        context: fetchContext,
                        success: { $0.map(\.asUnmanaged) },
                        subject: subject
                    )
                    subscription = subscriptionProvider
                    subscriptionProvider.start()
                    if let _self = self,
                       let _subjectCancellable = subjectCancellable,
                       let _fetchCancellable = fetchCancellable
                    {
                        _self.subscriptions.append(subscriptionProvider)
                        _self.cancellables.insert(_subjectCancellable)
                        _self.cancellables.insert(_fetchCancellable)
                    } else {
                        subjectCancellable?.cancel()
                        fetchCancellable?.cancel()
                        subscription?.cancel()
                    }
                    subject.send(value)
                }
            )
            return AnyCancellable {
                subscription?.cancel()
                self?.subscriptions.removeAll(where: { $0.id == id as AnyHashable })
            }
        }
    }

    private func _fetch<Model: UnmanagedModel>(
        _ request: NSFetchRequest<Model.RepoManaged>,
        fetchContext: NSManagedObjectContext
    )
        -> AnyPublisher<[Model], CoreDataRepositoryError>
    {
        Future { promise in
            fetchContext.perform {
                do {
                    let items = try fetchContext.fetch(request).map(\.asUnmanaged)
                    promise(.success(items))
                } catch {
                    promise(.failure(.coreData(error as NSError)))
                }
            }
        }.eraseToAnyPublisher()
    }
}
