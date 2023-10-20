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

/// Base class for other subscriptions.
class Subscription<
    Output,
    RequestResult: NSFetchRequestResult,
    ControllerResult: NSFetchRequestResult
>: NSObject, NSFetchedResultsControllerDelegate {
    let request: NSFetchRequest<RequestResult>
    let frc: NSFetchedResultsController<ControllerResult>
    private var streamContinuations: [AsyncStream<Result<Output, CoreDataError>>.Continuation]
    private var throwingStreamContinuations: [AsyncThrowingStream<Output, Error>.Continuation]

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
        streamContinuations = []
        throwingStreamContinuations = []
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
        for continuation in streamContinuations {
            continuation.finish()
        }
        for continuation in throwingStreamContinuations {
            continuation.finish()
        }
    }

    final func fail(_ error: CoreDataError) {
        for continuation in streamContinuations {
            continuation.yield(.failure(error))
        }
        for continuation in throwingStreamContinuations {
            continuation.yield(with: .failure(error))
        }
    }

    final func send(_ value: Output) {
        for continuation in streamContinuations {
            continuation.yield(.success(value))
        }
        for continuation in throwingStreamContinuations {
            continuation.yield(value)
        }
    }

    func stream() -> AsyncStream<Result<Output, CoreDataError>> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: Result<Output, CoreDataError>.self,
            bufferingPolicy: .unbounded
        )
        continuation.onTermination = { [self] _ in
            cancel()
        }
        streamContinuations.append(continuation)
        return stream
    }

    func throwingStream() -> AsyncThrowingStream<Output, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: Output.self,
            throwing: Error.self,
            bufferingPolicy: .unbounded
        )
        continuation.onTermination = { [self] _ in
            cancel()
        }
        throwingStreamContinuations.append(continuation)
        return stream
    }

    deinit {
        self.cancel()
    }
}

// MARK: where RequestResult == ControllerResult

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

// MARK: where RequestResult == NSDictionary, ControllerResult == NSManagedObject

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
