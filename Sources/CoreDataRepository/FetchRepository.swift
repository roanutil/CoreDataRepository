// FetchRepository.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2021 Andrew Roan

import Combine
import CoreData

/// A CoreData repository for fetching items with predicates, pagination, and sorting
public final class FetchRepository {
    // MARK: Properties

    /// The context used by the repository.
    public let context: NSManagedObjectContext
    var subscriptions = [SubscriptionProvider]()
    public var cancellables = [AnyCancellable]()

    // MARK: Init

    /// Initialize a repository
    /// - Parameters
    ///     - context: NSManagedObjectContext
    ///
    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: Return Types

    /// Return type for successful fetching. Includes parameters with items.
    public struct Success<Model: UnmanagedModel> {
        public let items: [Model]
        public let fetchRequest: NSFetchRequest<Model.RepoManaged>

        public init(items: [Model], fetchRequest: NSFetchRequest<Model.RepoManaged>) {
            self.items = items
            self.fetchRequest = fetchRequest
        }

        public var limit: Int { fetchRequest.fetchLimit }
        public var offset: Int { fetchRequest.fetchOffset }
        public var predicate: NSPredicate? { fetchRequest.predicate }
        public var sortDesc: [NSSortDescriptor]? { fetchRequest.sortDescriptors }
    }

    /// Return tpe for a failure to fetch. Includes parameters with error.
    public struct Failure<Model: UnmanagedModel>: Error {
        public let error: RepositoryErrors
        public let fetchRequest: NSFetchRequest<Model.RepoManaged>

        public init(error: RepositoryErrors, fetchRequest: NSFetchRequest<Model.RepoManaged>) {
            self.error = error
            self.fetchRequest = fetchRequest
        }

        public var nsError: NSError? {
            if case let .cocoa(nsError) = error {
                return nsError
            }
            return nil
        }

        public var localizedDescription: String? {
            if let desc = nsError?.localizedDescription {
                return desc
            }
            return nil
        }

        public var limit: Int { fetchRequest.fetchLimit }
        public var offset: Int { fetchRequest.fetchOffset }
        public var predicate: NSPredicate? { fetchRequest.predicate }
        public var sortDesc: [NSSortDescriptor]? { fetchRequest.sortDescriptors }
    }

    // MARK: Functions/Endpoints

    /// Fetch a single array of value types corresponding to a NSManagedObject sub class.
    /// - Parameters
    ///     - _ request: NSFetchRequest<Model.RepoManaged>
    /// - Returns
    ///     - AnyPublisher<Success<Model>, Failure<Model>>
    ///
    public func fetch<Model: UnmanagedModel>(_ request: NSFetchRequest<Model.RepoManaged>)
        -> AnyPublisher<Success<Model>, Failure<Model>>
    {
        Deferred { Future { [weak self] callback in
            guard let self = self else {
                return callback(.failure(Failure<Model>(error: .unknown, fetchRequest: request)))
            }
            self.context.perform {
                do {
                    let items = try self.context.fetch(request).map(\.asUnmanaged)
                    callback(.success(Success(items: items, fetchRequest: request)))
                } catch {
                    callback(.failure(Failure(error: .cocoa(error as NSError), fetchRequest: request)))
                }
            }
        }}.eraseToAnyPublisher()
    }

    public func subscription<Model: UnmanagedModel>(_ publisher: AnyPublisher<Success<Model>, Failure<Model>>)
        -> AnyPublisher<Success<Model>, Failure<Model>>
    {
        AnyPublisher.create { subscriber in
            let subject = PassthroughSubject<Success<Model>, Failure<Model>>()
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
                    let subscriptionProvider = RepositorySubscription(
                        id: id,
                        request: value.fetchRequest,
                        context: self.context,
                        success: { Success(items: $0.map(\.asUnmanaged), fetchRequest: value.fetchRequest) },
                        failure: { Failure(error: $0, fetchRequest: value.fetchRequest) },
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

// MARK: Extensions

extension AnyPublisher {
    public func subscription<Model: UnmanagedModel>(_ repository: FetchRepository) -> Self
        where Self.Output == FetchRepository.Success<Model>, Self.Failure == FetchRepository.Failure<Model>
    {
        repository.subscription(self)
    }
}

extension FetchRepository.Success: Equatable where Model: Equatable {}
extension FetchRepository.Failure: Equatable where Model: Equatable {}

extension FetchRepository.Success: Hashable where Model: Hashable {}
extension FetchRepository.Failure: Hashable where Model: Hashable {}
