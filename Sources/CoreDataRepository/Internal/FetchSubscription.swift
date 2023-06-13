// FetchSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

final class FetchSubscription<Result: RepositoryManagedModel>: Subscription<[Result.Unmanaged], Result, Result> {
    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc, subject] in
            guard let fetchedObjects = frc.fetchedObjects else {
                self?.start()
                return
            }
            subject.send(fetchedObjects.map(\.asUnmanaged))
        }
    }

    deinit {
        self.subject.send(completion: .finished)
    }
}
