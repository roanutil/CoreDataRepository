// CoreDataRepository+Delete.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData

extension CoreDataRepository {
    /// Delete an instance from the store.
    @inlinable
    public func delete(
        _ url: URL,
        transactionAuthor: String? = nil
    ) async -> Result<Void, CoreDataError> {
        await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            let id = try scratchPad.objectId(from: url).get()
            let object = try scratchPad.notDeletedObject(for: id)
            object.prepareForDeletion()
            scratchPad.delete(object)
            try scratchPad.save()
            try context.performAndWait {
                context.transactionAuthor = transactionAuthor
                try context.save()
                context.transactionAuthor = nil
            }
            return ()
        }
    }

    /// Delete an instance from the store.
    @inlinable
    public func delete(
        _ managedId: NSManagedObjectID,
        transactionAuthor: String? = nil
    ) async -> Result<Void, CoreDataError> {
        await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            let object = try scratchPad.notDeletedObject(for: managedId)
            object.prepareForDeletion()
            scratchPad.delete(object)
            try scratchPad.save()
            try context.performAndWait {
                context.transactionAuthor = transactionAuthor
                try context.save()
                context.transactionAuthor = nil
            }
            return ()
        }
    }

    /// Delete an instance from the store.
    @inlinable
    public func delete(
        _ item: some ReadableUnmanagedModel,
        transactionAuthor: String? = nil
    ) async -> Result<Void, CoreDataError> {
        await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            let object = try item.readManaged(from: scratchPad)
            guard !object.isDeleted else {
                throw CoreDataError.fetchedObjectIsFlaggedAsDeleted
            }
            object.prepareForDeletion()
            scratchPad.delete(object)
            try scratchPad.save()
            try context.performAndWait {
                context.transactionAuthor = transactionAuthor
                try context.save()
                context.transactionAuthor = nil
            }
            return ()
        }
    }
}
