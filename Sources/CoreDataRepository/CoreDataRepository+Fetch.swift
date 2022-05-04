// CoreDataRepository+Fetch.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import Combine
import CombineExt
import CoreData

extension CoreDataRepository {
    // MARK: Functions/Endpoints

    /// Fetch a single array of value types corresponding to a NSManagedObject sub class.
    /// - Parameters
    ///     - _ request: NSFetchRequest<Model.RepoManaged>
    /// - Returns
    ///     - AnyPublisher<Success<Model>, Failure<Model>>
    ///
    public func fetch<Model: UnmanagedModel>(_ request: NSFetchRequest<Model.RepoManaged>)
        -> AnyPublisher<[Model], Error>
    {
        Deferred { [context] in Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                do {
                    let items = try scratchPad.fetch(request).map(\.asUnmanaged)
                    promise(.success(items))
                } catch {
                    promise(.failure(error))
                }
            }

        }}.eraseToAnyPublisher()
    }

    public func fetchSubscription<Model: UnmanagedModel>(_ request: NSFetchRequest<Model.RepoManaged>)
        -> AnyPublisher<[Model], Error>
    {
        let publisher: AnyPublisher<[Model], Error> = fetch(request)
        return AnyPublisher.create { subscriber in
            let subject = PassthroughSubject<[Model], Error>()
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
                    let subscriptionProvider = FetchSubscription(
                        id: id,
                        request: request,
                        context: self.context,
                        success: { $0.map(\.asUnmanaged) },
                        subject: subject
                    )
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
