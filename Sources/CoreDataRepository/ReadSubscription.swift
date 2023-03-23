// ReadSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CoreData
import Foundation

final class ReadSubscription<Model: UnmanagedModel> {
    let id: AnyHashable
    private let objectId: NSManagedObjectID
    private let context: NSManagedObjectContext
    let subject: PassthroughSubject<Model, CoreDataRepositoryError>
    private var cancellables: Set<AnyCancellable> = []

    init(
        id: AnyHashable,
        objectId: NSManagedObjectID,
        context: NSManagedObjectContext,
        subject: PassthroughSubject<Model, CoreDataRepositoryError>
    ) {
        self.id = id
        self.subject = subject
        self.objectId = objectId
        self.context = context
    }
}

extension ReadSubscription: SubscriptionProvider {
    func manualFetch() {
        context.perform { [weak self, context, objectId] in
            guard let object = context.object(with: objectId) as? Model.RepoManaged else {
                return
            }
            self?.subject.send(object.asUnmanaged)
        }
    }

    func cancel() {
        subject.send(completion: .finished)
        cancellables.forEach { $0.cancel() }
    }

    func start() {
        context.perform { [weak self, context, objectId] in
            guard let object = context.object(with: objectId) as? Model.RepoManaged else {
                return
            }
            let startCancellable = object.objectWillChange.sink { [weak self] _ in
                self?.subject.send(object.asUnmanaged)
            }
            self?.cancellables.insert(startCancellable)
        }
    }
}
