// FetchSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

/// Subscription provider that sends updates when a fetch request changes
final class FetchSubscription<Model: UnmanagedModel>: Subscription<[Model], Model.ManagedModel, Model.ManagedModel> {
    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc, subject] in
            guard let fetchedObjects = frc.fetchedObjects else {
                self?.start()
                return
            }
            subject.send(fetchedObjects.map(Model.init(managed:)))
        }
    }

    deinit {
        self.subject.send(completion: .finished)
    }
}
