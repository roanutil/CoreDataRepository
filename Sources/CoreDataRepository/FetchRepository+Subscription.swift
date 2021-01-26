//
//  File.swift
//  
//
//  Created by Andrew Roan on 1/25/21.
//

import CoreData
import Combine

extension FetchRepository {
    public class Subscription<Model: UnmanagedModel>: NSObject, NSFetchedResultsControllerDelegate, SubscriptionProvider {
        public let id: AnyHashable
        private let request: NSFetchRequest<Model.RepoManaged>
        private let frc: NSFetchedResultsController<Model.RepoManaged>
        public let subject: PassthroughSubject<Success<Model>, Failure<Model>> = .init()

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

        // NSFetchedResultsControllerDelegate conformance
        public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            self.fetch()
        }

        public func manualFetch() {
            self.fetch()
        }

        public func cancel() {
            self.subject.send(completion: .finished)
        }

        func fail(_ failure: Failure<Model>) {
            self.subject.send(completion: .failure(failure))
        }
    }
}
