// Subscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CoreData
import Foundation

class Subscription<
    Output,
    RequestResult: NSFetchRequestResult,
    ControllerResult: NSFetchRequestResult
>: NSObject, NSFetchedResultsControllerDelegate {
    let request: NSFetchRequest<RequestResult>
    let frc: NSFetchedResultsController<ControllerResult>
    let subject: PassthroughSubject<Output, CoreDataError>

    init(
        fetchRequest: NSFetchRequest<RequestResult>,
        fetchResultControllerRequest: NSFetchRequest<ControllerResult>,
        context: NSManagedObjectContext
    ) {
        request = fetchRequest
        frc = NSFetchedResultsController(
            fetchRequest: fetchResultControllerRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        subject = PassthroughSubject()
        super.init()
        frc.delegate = self
        start()
    }

    func fetch() {}

    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        fetch()
    }

    func start() {
        do {
            try frc.performFetch()
        } catch let error as CocoaError {
            fail(.cocoa(error))
        } catch {
            fail(.unknown(error as NSError))
        }
    }

    func manualFetch() {
        fetch()
    }

    func cancel() {
        subject.send(completion: .finished)
    }

    func fail(_ error: CoreDataError) {
        subject.send(completion: .failure(error))
    }

    func stream() -> AsyncStream<Result<Output, CoreDataError>> {
        AsyncStream { [self] continuation in
            let task = Task {
                self.manualFetch()
                guard !Task.isCancelled else {
                    self.cancel()
                    continuation.finish()
                    return
                }
                for try await items in self.subject.values {
                    guard !Task.isCancelled else {
                        self.cancel()
                        continuation.finish()
                        return
                    }
                    continuation.yield(.success(items))
                    await Task.yield()
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func throwingStream() -> AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream { [self] continuation in
            let task = Task {
                self.manualFetch()
                guard !Task.isCancelled else {
                    self.cancel()
                    continuation.finish()
                    return
                }
                for try await items in self.subject.values {
                    guard !Task.isCancelled else {
                        self.cancel()
                        continuation.finish()
                        return
                    }
                    continuation.yield(with: .success(items))
                    await Task.yield()
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    deinit {
        self.subject.send(completion: .finished)
    }
}

extension Subscription where RequestResult == ControllerResult {
    convenience init(
        request: NSFetchRequest<RequestResult>,
        context: NSManagedObjectContext
    ) {
        self.init(
            fetchRequest: request,
            fetchResultControllerRequest: request,
            context: context
        )
    }
}

extension Subscription where RequestResult == NSDictionary, ControllerResult == NSManagedObject {
    convenience init(
        request: NSFetchRequest<NSDictionary>,
        context: NSManagedObjectContext
    ) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: request.entityName!)
        fetchRequest.predicate = request.predicate
        fetchRequest.sortDescriptors = request.sortDescriptors
        self.init(
            fetchRequest: request,
            fetchResultControllerRequest: fetchRequest,
            context: context
        )
    }
}
