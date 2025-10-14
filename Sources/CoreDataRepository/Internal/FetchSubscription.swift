// FetchSubscription.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

@preconcurrency import CoreData
import Foundation

/// Subscription provider that sends updates when a fetch request changes
@usableFromInline
final class FetchSubscription<Model: FetchableUnmanagedModel>: Subscription<
    [Model],
    Model.ManagedModel,
    Model.ManagedModel
>, @unchecked Sendable {
    @usableFromInline
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
}
