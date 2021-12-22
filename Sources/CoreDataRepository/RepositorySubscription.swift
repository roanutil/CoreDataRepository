// RepositorySubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2021 Andrew Roan

import Combine
import CoreData
import Foundation

/// Re-fetches data as the context changes until canceled
class RepositorySubscription<
    Success,
    Failure: Error,
    Result: NSFetchRequestResult
>: NSObject, NSFetchedResultsControllerDelegate, SubscriptionProvider {
    // MARK: Properties

    /// Enables easy cancellation and cleanup of a subscription as a repository may
    /// have multiple subscriptions running at once.
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
        frc = NSFetchedResultsController(
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
            frc.delegate = self
        } else {
            changeNotificationCancellable = NotificationCenter.default.publisher(
                for: .NSManagedObjectContextObjectsDidChange,
                object: context
            ).sink(receiveValue: { _ in
                self.fetch()
            })
        }
    }

    // MARK: Private methods

    /// Get and send new data for fetch request
    private func fetch() {
        frc.managedObjectContext.perform {
            if (self.frc.fetchedObjects ?? []).isEmpty {
                self.start()
            }
            guard let items = self.frc.fetchedObjects else { return }
            self.subject.send(self.success(items))
        }
    }

    // MARK: Public methods

    // MARK: NSFetchedResultsControllerDelegate conformance

    public func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        fetch()
    }

    public func start() {
        do {
            try frc.performFetch()
        } catch {
            fail(failure(.cocoa(error as NSError)))
        }
    }

    /// Manually initiate a fetch and publish data
    public func manualFetch() {
        fetch()
    }

    /// Cancel the subscription
    public func cancel() {
        subject.send(completion: .finished)
    }

    /// Finish the subscription with a failure
    /// - Parameters
    ///     - _ failure: Failure
    public func fail(_ failure: Failure) {
        subject.send(completion: .failure(failure))
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
