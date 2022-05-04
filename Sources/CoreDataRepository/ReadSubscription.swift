// ReadSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import Combine
import CoreData
import Foundation

final class ReadSubscription<Model: UnmanagedModel> {
    let id: AnyHashable
    private var object: Model.RepoManaged
    let subject: PassthroughSubject<Model, Error>
    private var cancellable: AnyCancellable?

    init(id: AnyHashable, object: Model.RepoManaged, subject: PassthroughSubject<Model, Error>) {
        self.id = id
        self.subject = subject
        self.object = object
    }
}

extension ReadSubscription: SubscriptionProvider {
    func manualFetch() {
        subject.send(object.asUnmanaged)
    }

    func cancel() {
        subject.send(completion: .finished)
    }

    func start() {
        cancellable = object.objectWillChange.sink { [weak self] _ in
            if let unmanaged = self?.object.asUnmanaged {
                self?.subject.send(unmanaged)
            }
        }
    }
}
