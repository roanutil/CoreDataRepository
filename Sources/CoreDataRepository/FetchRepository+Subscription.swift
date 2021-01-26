//
//  File.swift
//  
//
//  Created by Andrew Roan on 1/25/21.
//

import CoreData
import Combine

extension FetchRepository {
    /// Re-fetches data as the context changes until canceled
    public class Subscription<Model: UnmanagedModel>: NSObject, NSFetchedResultsControllerDelegate, SubscriptionProvider {
        // MARK: Properties
        /// Enables easy cancellation and cleanup of a subscription as a repository may have multiple subscriptions running at once.
        public let id: AnyHashable
        /// The fetch request to monitor
        private let request: NSFetchRequest<Model.RepoManaged>
        /// Fetched results controller that notifies the context has changed
        private let frc: NSFetchedResultsController<Model.RepoManaged>
        /// Subject that sends data as updates happen
        public let subject: PassthroughSubject<Success<Model>, Failure<Model>> = .init()

        // MARK: Init
        /// Initializes an instance of Subscription
        /// - Parameters
        ///     - id: AnyHashable
        ///     - request: NSFetchRequest<Model.RepoManaged>
        ///     - context: NSManagedObjectContext
        public init(id: AnyHashable, request: NSFetchRequest<Model.RepoManaged>, context: NSManagedObjectContext) {
            self.id = id
            self.request = request
            self.frc = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            super.init()
            self.frc.delegate = self
        }

        // MARK: Private methods
        /// Get and send new data for fetch request
        private func fetch() {
            self.frc.managedObjectContext.perform {
                if (self.frc.fetchedObjects ?? []).isEmpty {
                    do {
                        try self.frc.performFetch()
                    } catch {
                        self.fail(Failure(error: .cocoa(error as NSError), fetchRequest: self.request))
                    }
                }
                guard let items = self.frc.fetchedObjects else { return }
                self.subject.send(Success(items: items.map { $0.asUnmanaged }, fetchRequest: self.request))
                return
            }
        }

        // MARK: Public methods
        // MARK: NSFetchedResultsControllerDelegate conformance
        public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            self.fetch()
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
        ///     - _ failure: Failure<Model>
        public func fail(_ failure: Failure<Model>) {
            self.subject.send(completion: .failure(failure))
        }
    }
}
