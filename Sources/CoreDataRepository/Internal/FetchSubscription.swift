// FetchSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation

/// Subscription provider that sends updates when a fetch request changes
final class FetchSubscription<Model: UnmanagedModel>: Subscription<[Model], Model.ManagedModel, Model.ManagedModel> {
    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc, subject, request] in
            guard frc.fetchedObjects != nil else {
                self?.start()
                return
            }

            do {
                let result = try frc.managedObjectContext.fetch(request)
                try subject.send(result.map(Model.init(managed:)))
            } catch let error as CocoaError {
                subject.send(completion: .failure(.cocoa(error)))
                return
            } catch {
                subject.send(completion: .failure(.unknown(error as NSError)))
                return
            }
        }
    }

    deinit {
        self.subject.send(completion: .finished)
    }
}
