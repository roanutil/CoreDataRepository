// BaseSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

/// Base class for other subscriptions.
@usableFromInline
class BaseSubscription<
    Output,
    RequestResult: NSFetchRequestResult,
    ControllerResult: NSFetchRequestResult
>: NSObject, NSFetchedResultsControllerDelegate {
    let request: NSFetchRequest<RequestResult>
    let frc: NSFetchedResultsController<ControllerResult>

    @usableFromInline
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
        super.init()
        frc.delegate = self
        start()
    }

    @usableFromInline
    func fetch() {
        fatalError("\(Self.self).\(#function) is not implemented.")
    }

    @usableFromInline
    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        fetch()
    }

    @usableFromInline
    func start() {
        do {
            try frc.performFetch()
        } catch let error as CocoaError {
            fail(.cocoa(error))
        } catch {
            fail(.unknown(error as NSError))
        }
    }

    @usableFromInline
    func manualFetch() {
        fetch()
    }

    @usableFromInline
    func cancel() {
        fatalError("\(Self.self).\(#function) is not implemented.")
    }

    @usableFromInline
    func fail(_: CoreDataError) {
        fatalError("\(Self.self).\(#function) is not implemented.")
    }

    @usableFromInline
    func send(_: Output) {
        fatalError("\(Self.self).\(#function) is not implemented.")
    }

    deinit {
        self.cancel()
    }
}
