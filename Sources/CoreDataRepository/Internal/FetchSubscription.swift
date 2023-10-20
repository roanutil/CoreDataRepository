// FetchSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

/// StreamProvider provider that sends updates when a fetch request changes
final class FetchStreamProvider<Model: UnmanagedModel>: StreamProvider<
    [Model],
    Model.ManagedModel,
    Model.ManagedModel
> {
    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc, request] in
            guard frc.fetchedObjects != nil else {
                self?.start()
                return
            }

            do {
                let result = try frc.managedObjectContext.fetch(request)
                try self?.send(result.map(Model.init(managed:)))
            } catch let error as CocoaError {
                self?.fail(.cocoa(error))
                return
            } catch {
                self?.fail(.unknown(error as NSError))
                return
            }
        }
    }

    deinit {
        self.cancel()
    }
}

/// StreamProvider provider that sends updates when a fetch request changes
final class FetchThrowingStreamProvider<Model: UnmanagedModel>: ThrowingStreamProvider<
    [Model],
    Model.ManagedModel,
    Model.ManagedModel
> {
    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc, request] in
            guard frc.fetchedObjects != nil else {
                self?.start()
                return
            }

            do {
                let result = try frc.managedObjectContext.fetch(request)
                try self?.send(result.map(Model.init(managed:)))
            } catch let error as CocoaError {
                self?.fail(.cocoa(error))
                return
            } catch {
                self?.fail(.unknown(error as NSError))
                return
            }
        }
    }

    deinit {
        self.cancel()
    }
}
