//
//  FetchRepository.swift
//
//  Created by Andrew Roan on 1/15/21.
//

import CoreData
import Combine

/// A CoreData repository for fetching items with predicates, pagination, and sorting
public final class FetchRepository {
    // MARK: Properties
    /// The context used by the repository.
    public let context: NSManagedObjectContext
    public var subscriptions = [SubscriptionProvider]()
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

        var limit: Int { fetchRequest.fetchLimit }
        var offset: Int { fetchRequest.fetchOffset }
        var predicate: NSPredicate? { fetchRequest.predicate }
        var sortDesc: [NSSortDescriptor]? { fetchRequest.sortDescriptors }
    }

    /// Return tpe for a failure to fetch. Includes parameters with error.
    public struct Failure<Model: UnmanagedModel>: Error {
        public let error: RepositoryErrors
        public let fetchRequest: NSFetchRequest<Model.RepoManaged>

        public init(error: RepositoryErrors, fetchRequest: NSFetchRequest<Model.RepoManaged>) {
            self.error = error
            self.fetchRequest = fetchRequest
        }

        var nsError: NSError? {
            if case let .cocoa(nsError) = error {
                return nsError
            }
            return nil
        }
        var localizedDescription: String? {
            if let desc = nsError?.localizedDescription {
                return desc
            }
            return nil
        }

        var limit: Int { fetchRequest.fetchLimit }
        var offset: Int { fetchRequest.fetchOffset }
        var predicate: NSPredicate? { fetchRequest.predicate }
        var sortDesc: [NSSortDescriptor]? { fetchRequest.sortDescriptors }
    }

    // MARK: Functions/Endpoints
    /// Fetch a single array of value types corresponding to a NSManagedObject sub class.
    /// - Parameters
    ///     - _ request: NSFetchRequest<Model.RepoManaged>
    /// - Returns
    ///     - AnyPublisher<Success<Model>, Failure<Model>>
    ///
    public func fetch<Model: UnmanagedModel>(_ request: NSFetchRequest<Model.RepoManaged>) -> AnyPublisher<Success<Model>, Failure<Model>> {
        Deferred { Future { [weak self] callback in
            guard let self = self else {
                return callback(.failure(Failure<Model>(error: .unknown, fetchRequest: request)))
            }
            self.context.perform {
                do {
                    let items = try self.context.fetch(request).map { $0.asUnmanaged }
                    callback(.success(Success(items: items, fetchRequest: request)))
                } catch {
                    callback(.failure(Failure(error: .cocoa(error as NSError), fetchRequest: request)))
                }
            }
        }}.eraseToAnyPublisher()
    }

    public func fetchSubscription<Model: UnmanagedModel>(_ request: NSFetchRequest<Model.RepoManaged>) -> AnyPublisher<Success<Model>, Failure<Model>> {
        AnyPublisher.create { [weak self] subscriber -> AnyCancellable in
            guard let self = self else {
                subscriber.send(completion: .failure(Failure(error: .unknown, fetchRequest: request)))
                return AnyCancellable {}
            }
            let id = UUID()
            let subscription = FetchRepository.Subscription<Model>(
                id: id,
                request: request,
                context: self.context
            )
            subscription.subject.sink(receiveCompletion: subscriber.send, receiveValue: subscriber.send).store(in: &self.cancellables)
            self.subscriptions.append(subscription)
            subscription.manualFetch()
            return AnyCancellable {
                subscription.cancel()
                self.subscriptions.removeAll(where: { $0.id == subscription.id })
            }
        }
    }
}
