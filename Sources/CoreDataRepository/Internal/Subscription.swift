// Subscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

/// Base class for other subscriptions.
class Subscription<
    Output,
    RequestResult: NSFetchRequestResult,
    ControllerResult: NSFetchRequestResult
>: NSObject, NSFetchedResultsControllerDelegate {
    let request: NSFetchRequest<RequestResult>
    let frc: NSFetchedResultsController<ControllerResult>
    private let continuation: AsyncStream<Result<Output, CoreDataError>>.Continuation

    init(
        fetchRequest: NSFetchRequest<RequestResult>,
        fetchResultControllerRequest: NSFetchRequest<ControllerResult>,
        context: NSManagedObjectContext,
        continuation: AsyncStream<Result<Output, CoreDataError>>.Continuation
    ) {
        request = fetchRequest
        frc = NSFetchedResultsController(
            fetchRequest: fetchResultControllerRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.continuation = continuation
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
        continuation.finish()
    }

    final func fail(_ error: CoreDataError) {
        continuation.yield(.failure(error))
    }

    final func send(_ value: Output) {
        continuation.yield(.success(value))
    }

    deinit {
        self.cancel()
    }
}

// MARK: where RequestResult == ControllerResult

extension Subscription where RequestResult == ControllerResult {
    convenience init(
        request: NSFetchRequest<RequestResult>,
        context: NSManagedObjectContext,
        continuation: AsyncStream<Result<Output, CoreDataError>>.Continuation
    ) {
        self.init(
            fetchRequest: request,
            fetchResultControllerRequest: request,
            context: context,
            continuation: continuation
        )
    }
}

// MARK: where RequestResult == NSDictionary, ControllerResult == NSManagedObject

extension Subscription where RequestResult == NSDictionary, ControllerResult == NSManagedObject {
    convenience init(
        request: NSFetchRequest<NSDictionary>,
        context: NSManagedObjectContext,
        continuation: AsyncStream<Result<Output, CoreDataError>>.Continuation
    ) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: request.entityName!)
        fetchRequest.predicate = request.predicate
        fetchRequest.sortDescriptors = request.sortDescriptors
        self.init(
            fetchRequest: request,
            fetchResultControllerRequest: fetchRequest,
            context: context,
            continuation: continuation
        )
    }
}
