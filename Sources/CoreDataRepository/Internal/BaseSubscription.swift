// BaseSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

/// Base class for other subscriptions.
class BaseSubscription<
    Output,
    RequestResult: NSFetchRequestResult,
    ControllerResult: NSFetchRequestResult
>: NSObject, NSFetchedResultsControllerDelegate {
    let request: NSFetchRequest<RequestResult>
    let frc: NSFetchedResultsController<ControllerResult>

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

    func fetch() {
        fatalError("\(Self.self).\(#function) is not implemented.")
    }

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
        fatalError("\(Self.self).\(#function) is not implemented.")
    }

    func fail(_: CoreDataError) {
        fatalError("\(Self.self).\(#function) is not implemented.")
    }

    func send(_: Output) {
        fatalError("\(Self.self).\(#function) is not implemented.")
    }

    deinit {
        self.cancel()
    }
}
