// CoreDataRepository+Delete_Batch.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData

extension CoreDataRepository {
    /// Delete from the store with a batch of unmanaged models.
    ///
    /// This operation is non-atomic. Each instance may succeed or fail individually.
    @inlinable
    public func delete(
        _ managedIdUrls: [URL],
        transactionAuthor: String? = nil
    ) async -> (success: [URL], failed: [CoreDataBatchError<URL>]) {
        var successes = [URL]()
        var failures = [CoreDataBatchError<URL>]()
        for managedIdUrl in managedIdUrls {
            switch await delete(managedIdUrl, transactionAuthor: transactionAuthor) {
            case .success:
                successes.append(managedIdUrl)
            case let .failure(error):
                failures.append(CoreDataBatchError(item: managedIdUrl, error: error))
            }
        }
        return (success: successes, failed: failures)
    }

    /// Delete from the store with a batch of unmanaged models.
    ///
    /// This operation is non-atomic. Each instance may succeed or fail individually.
    @inlinable
    public func delete(
        _ managedIds: [NSManagedObjectID],
        transactionAuthor: String? = nil
    ) async -> (success: [NSManagedObjectID], failed: [CoreDataBatchError<NSManagedObjectID>]) {
        var successes = [NSManagedObjectID]()
        var failures = [CoreDataBatchError<NSManagedObjectID>]()
        for managedId in managedIds {
            switch await delete(managedId, transactionAuthor: transactionAuthor) {
            case .success:
                successes.append(managedId)
            case let .failure(error):
                failures.append(CoreDataBatchError(item: managedId, error: error))
            }
        }
        return (success: successes, failed: failures)
    }

    /// Delete from the store with a batch of unmanaged models.
    ///
    /// This operation is non-atomic. Each instance may succeed or fail individually.
    @inlinable
    public func delete<Model: ReadableUnmanagedModel>(
        _ items: [Model],
        transactionAuthor: String? = nil
    ) async -> (success: [Model], failed: [CoreDataBatchError<Model>]) {
        var successes = [Model]()
        var failures = [CoreDataBatchError<Model>]()
        for item in items {
            switch await delete(item, transactionAuthor: transactionAuthor) {
            case .success:
                successes.append(item)
            case let .failure(error):
                failures.append(CoreDataBatchError(item: item, error: error))
            }
        }
        return (success: successes, failed: failures)
    }

    /// Delete from the store with a batch of unmanaged models.
    @inlinable
    public func deleteAtomically(
        _ managedIdUrls: [URL],
        transactionAuthor: String? = nil
    ) async -> Result<Void, CoreDataError> {
        let context = Transaction.current?.context ?? context
        let notTransaction = Transaction.current == nil
        return await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            for url in managedIdUrls {
                let id = try scratchPad.objectId(from: url).get()
                let object = try scratchPad.notDeletedObject(for: id)
                object.prepareForDeletion()
                scratchPad.delete(object)
            }
            try scratchPad.save()
            if notTransaction {
                try context.performAndWait {
                    context.transactionAuthor = transactionAuthor
                    try context.save()
                    context.transactionAuthor = nil
                }
            }
            return ()
        }
    }

    /// Delete from the store with a batch of unmanaged models.
    @inlinable
    public func deleteAtomically(
        _ managedIds: [NSManagedObjectID],
        transactionAuthor: String? = nil
    ) async -> Result<Void, CoreDataError> {
        let context = Transaction.current?.context ?? context
        let notTransaction = Transaction.current == nil
        return await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            for managedId in managedIds {
                let object = try scratchPad.notDeletedObject(for: managedId)
                object.prepareForDeletion()
                scratchPad.delete(object)
            }
            try scratchPad.save()
            if notTransaction {
                try context.performAndWait {
                    context.transactionAuthor = transactionAuthor
                    try context.save()
                    context.transactionAuthor = nil
                }
            }
            return ()
        }
    }

    /// Delete from the store with a batch of unmanaged models.
    @inlinable
    public func deleteAtomically(
        _ items: [some ReadableUnmanagedModel],
        transactionAuthor: String? = nil
    ) async -> Result<Void, CoreDataError> {
        let context = Transaction.current?.context ?? context
        let notTransaction = Transaction.current == nil
        return await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            for item in items {
                let object = try item.readManaged(from: scratchPad)
                guard !object.isDeleted else {
                    throw CoreDataError.fetchedObjectIsFlaggedAsDeleted
                }
                object.prepareForDeletion()
                scratchPad.delete(object)
            }
            try scratchPad.save()
            if notTransaction {
                try context.performAndWait {
                    context.transactionAuthor = transactionAuthor
                    try context.save()
                    context.transactionAuthor = nil
                }
            }
            return ()
        }
    }
}
