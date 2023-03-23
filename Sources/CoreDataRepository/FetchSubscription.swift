// FetchSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CoreData
import Foundation

/// Re-fetches data as the context changes until canceled
final class FetchSubscription<
    Success,
    Result: NSFetchRequestResult
>: NSObject, NSFetchedResultsControllerDelegate, SubscriptionProvider {
    // MARK: Properties

    /// Enables easy cancellation and cleanup of a subscription as a repository may
    /// have multiple subscriptions running at once.
    let id: AnyHashable
    /// The fetch request to monitor
    private let request: NSFetchRequest<Result>
    /// Fetched results controller that notifies the context has changed
    private let frc: NSFetchedResultsController<Result>
    /// Subject that sends data as updates happen
    let subject: PassthroughSubject<Success, CoreDataRepositoryError>
    /// Closure to construct Success
    private let success: ([Result]) -> Success

    private var changeNotificationCancellable: AnyCancellable?

    // MARK: Init

    /// Initializes an instance of Subscription
    /// - Parameters
    ///     - id: AnyHashable
    ///     - request: NSFetchRequest<Model.RepoManaged>
    ///     - context: NSManagedObjectContext
    ///     - success: @escaping ([Result]) -> Success
    ///     - failure: @escaping (RepositoryErrors) -> Failure
    init(
        id: AnyHashable,
        request: NSFetchRequest<Result>,
        context: NSManagedObjectContext,
        success: @escaping ([Result]) -> Success,
        subject: PassthroughSubject<Success, CoreDataRepositoryError> = .init()
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

    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        fetch()
    }

    func start() {
        do {
            try frc.performFetch()
        } catch {
            fail(.coreData(error as NSError))
        }
    }

    /// Manually initiate a fetch and publish data
    func manualFetch() {
        fetch()
    }

    /// Cancel the subscription
    func cancel() {
        subject.send(completion: .finished)
    }

    /// Finish the subscription with a failure
    /// - Parameters
    ///     - _ failure: Failure
    func fail(_ error: CoreDataRepositoryError) {
        subject.send(completion: .failure(error))
    }

    // Helps me sleep at night
    deinit {
        self.subject.send(completion: .finished)
    }
}
