//
//  RepositorySubscription.swift
//  
//
//  Created by Andrew Roan on 1/25/21.
//

import Foundation
import CoreData
import Combine

/// Re-fetches data as the context changes until canceled
class RepositorySubscription<
    Success,
    Failure: Error,
    Result: NSFetchRequestResult
>: NSObject, NSFetchedResultsControllerDelegate, SubscriptionProvider {
    // MARK: Properties
    /// Enables easy cancellation and cleanup of a subscription as a repository may have multiple subscriptions running at once.
    public let id: AnyHashable
    /// The fetch request to monitor
    private let request: NSFetchRequest<Result>
    /// Fetched results controller that notifies the context has changed
    private let frc: NSFetchedResultsController<Result>
    /// Subject that sends data as updates happen
    public let subject: PassthroughSubject<Success, Failure>
    /// Closure to construct Success
    private let success: ([Result]) -> Success
    /// Closure to construct Failure
    private let failure: (RepositoryErrors) -> Failure

    private var changeNotificationCancellable: AnyCancellable?

    // MARK: Init
    /// Initializes an instance of Subscription
    /// - Parameters
    ///     - id: AnyHashable
    ///     - request: NSFetchRequest<Model.RepoManaged>
    ///     - context: NSManagedObjectContext
    ///     - success: @escaping ([Result]) -> Success
    ///     - failure: @escaping (RepositoryErrors) -> Failure
    public init(
        id: AnyHashable,
        request: NSFetchRequest<Result>,
        context: NSManagedObjectContext,
        success: @escaping ([Result]) -> Success,
        failure: @escaping (RepositoryErrors) -> Failure,
        subject: PassthroughSubject<Success, Failure> = .init()
    ) {
        self.id = id
        self.request = request
        self.frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.success = success
        self.failure = failure
        self.subject = subject
        super.init()
        if request.resultType != .dictionaryResultType {
            self.frc.delegate = self
        } else {
            self.changeNotificationCancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context).sink(receiveValue: { _ in
                self.fetch()
            })
        }
    }

    // MARK: Private methods

    /// Get and send new data for fetch request
    private func fetch() {
        self.frc.managedObjectContext.perform {
            if (self.frc.fetchedObjects ?? []).isEmpty {
                self.start()
            }
            guard let items = self.frc.fetchedObjects else { return }
            self.subject.send(self.success(items))
            return
        }
    }

    // MARK: Public methods
    // MARK: NSFetchedResultsControllerDelegate conformance
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.fetch()
    }

    public func start() {
        do {
            try self.frc.performFetch()
        } catch {
            self.fail(self.failure(.cocoa(error as NSError)))
        }
    }

    /// Manually initiate a fetch and publish data
    public func manualFetch() {
        self.fetch()
    }
    
    /// Cancel the subscription
    public func cancel() {
        self.subject.send(completion: .finished)
    }

    /// Finish the subscription with a failure
    /// - Parameters
    ///     - _ failure: Failure
    public func fail(_ failure: Failure) {
        self.subject.send(completion: .failure(failure))
    }

    // Helps me sleep at night
    deinit {
        self.subject.send(completion: .finished)
    }
}

protocol SubscriptionSuccess {
    associatedtype Data
    associatedtype RequestResult: NSFetchRequestResult
    static func factory(from: Self) -> ((Data) -> Self)
    var request: NSFetchRequest<RequestResult> { get }
}

protocol SubscriptionFailure: Error {
    associatedtype RequestResult: NSFetchRequestResult
    static func factory(from: Self) -> ((RepositoryErrors) -> Self)
    var request: NSFetchRequest<RequestResult> { get }
}
