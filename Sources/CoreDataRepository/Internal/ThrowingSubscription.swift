// ThrowingSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

/// Base class for other subscriptions.
class ThrowingSubscription<
    Output,
    RequestResult: NSFetchRequestResult,
    ControllerResult: NSFetchRequestResult
>: BaseSubscription<Output, RequestResult, ControllerResult> {
    private let continuation: AsyncThrowingStream<Output, Error>.Continuation

    init(
        fetchRequest: NSFetchRequest<RequestResult>,
        fetchResultControllerRequest: NSFetchRequest<ControllerResult>,
        context: NSManagedObjectContext,
        continuation: AsyncThrowingStream<Output, Error>.Continuation
    ) {
        self.continuation = continuation
        super.init(
            fetchRequest: fetchRequest,
            fetchResultControllerRequest: fetchResultControllerRequest,
            context: context
        )
    }

    override func cancel() {
        continuation.finish()
    }

    override final func fail(_ error: CoreDataError) {
        continuation.yield(with: .failure(error))
    }

    override final func send(_ value: Output) {
        continuation.yield(with: .success(value))
    }
}

// MARK: where RequestResult == ControllerResult

extension ThrowingSubscription where RequestResult == ControllerResult {
    convenience init(
        request: NSFetchRequest<RequestResult>,
        context: NSManagedObjectContext,
        continuation: AsyncThrowingStream<Output, Error>.Continuation
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

extension ThrowingSubscription where RequestResult == NSDictionary, ControllerResult == NSManagedObject {
    convenience init(
        request: NSFetchRequest<NSDictionary>,
        context: NSManagedObjectContext,
        continuation: AsyncThrowingStream<Output, Error>.Continuation
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
