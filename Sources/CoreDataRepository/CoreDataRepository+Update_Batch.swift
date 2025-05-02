// CoreDataRepository+Update_Batch.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

extension CoreDataRepository {
    /// Update the store with a batch of unmanaged models.
    ///
    /// This operation is non-atomic. Each instance may succeed or fail individually.
    @inlinable
    public func update<Model>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> (success: [Model], failed: [CoreDataBatchError<Model>]) where Model: ReadableUnmanagedModel,
        Model: WritableUnmanagedModel
    {
        var successes = [Model]()
        var failures = [CoreDataBatchError<Model>]()
        for item in items {
            switch await update(with: item, transactionAuthor: transactionAuthor) {
            case let .success(success):
                successes.append(success)
            case let .failure(error):
                failures.append(.init(item: item, error: error))
            }
        }
        return (success: successes, failed: failures)
    }

    /// Update the store with a batch of unmanaged models.
    @inlinable
    public func updateAtomically<Model>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> Result<[Model], CoreDataError> where Model: ReadableUnmanagedModel, Model: WritableUnmanagedModel {
        await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            let objects = try items.map { item in
                let managed = try item.readManaged(from: scratchPad)
                try item.updating(managed: managed)
                return managed
            }
            try scratchPad.save()
            try context.performAndWait {
                context.transactionAuthor = transactionAuthor
                try context.save()
                context.transactionAuthor = nil
            }
            return try objects.map(Model.init(managed:))
        }
    }
}
