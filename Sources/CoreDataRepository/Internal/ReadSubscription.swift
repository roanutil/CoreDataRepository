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
    private let objectId: NSManagedObjectID
    private let context: NSManagedObjectContext
    let subject: PassthroughSubject<Model, CoreDataRepositoryError>
    private var cancellables: Set<AnyCancellable> = []

    func manualFetch() {
        context.perform { [context, objectId, subject] in
            guard let object = context.object(with: objectId) as? Model.RepoManaged else {
                return
            }
            subject.send(object.asUnmanaged)
        }
    }

    func cancel() {
        subject.send(completion: .finished)
        cancellables.forEach { $0.cancel() }
    }

    func start() {
        context.perform { [weak self, context, objectId, subject] in
            guard let object = context.object(with: objectId) as? Model.RepoManaged else {
                return
            }
            let startCancellable = object.objectWillChange.sink { [subject] _ in
                subject.send(object.asUnmanaged)
            }
            self?.cancellables.insert(startCancellable)
        }
    }

    init(
        objectId: NSManagedObjectID,
        context: NSManagedObjectContext
    ) {
        subject = PassthroughSubject()
        self.objectId = objectId
        self.context = context
    }

    deinit {
        self.subject.send(completion: .finished)
    }
}
