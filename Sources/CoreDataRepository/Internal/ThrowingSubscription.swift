// ThrowingSubscription.swift
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
class ThrowingSubscription<
    Output,
    RequestResult: NSFetchRequestResult,
    ControllerResult: NSFetchRequestResult
>: BaseSubscription<Output, RequestResult, ControllerResult> {
    private let continuation: AsyncThrowingStream<Output, Error>.Continuation

    @usableFromInline
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

    @usableFromInline
    override func cancel() {
        continuation.finish()
    }

    @usableFromInline
    override final func fail(_ error: CoreDataError) {
        continuation.yield(with: .failure(error))
    }

    @usableFromInline
    override final func send(_ value: Output) {
        continuation.yield(with: .success(value))
    }
}

// MARK: where RequestResult == ControllerResult

extension ThrowingSubscription where RequestResult == ControllerResult {
    @usableFromInline
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
    @usableFromInline
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
