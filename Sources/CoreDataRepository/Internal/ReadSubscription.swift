// ReadSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import Combine
import CoreData
import Foundation

/// Subscription provider that sends updates when a single ``NSManagedObject`` changes
@usableFromInline
final class ReadSubscription<Model: UnmanagedReadOnlyModel> {
    private let objectId: NSManagedObjectID
    private let context: NSManagedObjectContext
    private var cancellables: Set<AnyCancellable>
    private let continuation: AsyncStream<Result<Model, CoreDataError>>.Continuation

    @usableFromInline
    func manualFetch() {
        context.perform { [weak self, context, objectId] in
            guard let object = context.object(with: objectId) as? Model.ManagedModel else {
                return
            }
            do {
                let item = try Model(managed: object)
                self?.continuation.yield(.success(item))
            } catch {
                self?.continuation.yield(.failure(CoreDataError.unknown(error as NSError)))
            }
        }
    }

    @usableFromInline
    func cancel() {
        continuation.finish()
        cancellables.forEach { $0.cancel() }
    }

    @usableFromInline
    func start() {
        context.perform { [weak self, context, objectId] in
            guard let object = context.object(with: objectId) as? Model.ManagedModel else {
                return
            }
            let startCancellable = object.objectWillChange.sink { [weak self] _ in
                do {
                    let item = try Model(managed: object)
                    self?.continuation.yield(.success(item))
                } catch {
                    self?.continuation.yield(.failure(CoreDataError.unknown(error as NSError)))
                }
            }
            self?.cancellables.insert(startCancellable)
        }
    }

    @usableFromInline
    init(
        objectId: NSManagedObjectID,
        context: NSManagedObjectContext,
        continuation: AsyncStream<Result<Model, CoreDataError>>.Continuation
    ) {
        self.objectId = objectId
        self.context = context
        cancellables = []
        self.continuation = continuation
    }

    deinit {
        self.cancellables.forEach { $0.cancel() }
        self.continuation.finish()
    }
}
