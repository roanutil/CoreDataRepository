// CoreDataRepository+Update.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

extension CoreDataRepository {
    /// Update the store with an unmanaged model.
    @inlinable
    public func update<Model>(
        with item: Model,
        transactionAuthor: String? = nil
    ) async -> Result<Model, CoreDataError> where Model: ReadableUnmanagedModel, Model: WritableUnmanagedModel {
        let context = Transaction.current?.context ?? context
        let notTransaction = Transaction.current == nil
        return await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            let managed = try item.readManaged(from: scratchPad)
            try item.updating(managed: managed)
            try scratchPad.save()
            if notTransaction {
                try context.performAndWait {
                    context.transactionAuthor = transactionAuthor
                    try context.save()
                    context.transactionAuthor = nil
                }
            }
            return try Model(managed: managed)
        }
    }

    /// Update the store with an unmanaged model.
    @inlinable
    public func update<Model: UnmanagedModel>(
        _ managedId: NSManagedObjectID,
        with item: Model,
        transactionAuthor: String? = nil
    ) async -> Result<Model, CoreDataError> where Model: FetchableUnmanagedModel, Model: WritableUnmanagedModel {
        let context = Transaction.current?.context ?? context
        let notTransaction = Transaction.current == nil
        return await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            let object = try scratchPad.notDeletedObject(for: managedId)
            let repoManaged: Model.ManagedModel = try object.asManagedModel()
            try item.updating(managed: repoManaged)
            try scratchPad.save()
            if notTransaction {
                try context.performAndWait {
                    context.transactionAuthor = transactionAuthor
                    try context.save()
                    context.transactionAuthor = nil
                }
            }
            return try Model(managed: repoManaged)
        }
    }

    /// Update the store with an unmanaged model.
    @inlinable
    public func update<Model: UnmanagedModel>(
        _ managedIdUrl: URL,
        with item: Model,
        transactionAuthor: String? = nil
    ) async -> Result<Model, CoreDataError> where Model: FetchableUnmanagedModel, Model: WritableUnmanagedModel {
        let context = Transaction.current?.context ?? context
        let notTransaction = Transaction.current == nil
        return await context.performInScratchPad(schedule: .enqueued) { [context] scratchPad in
            scratchPad.transactionAuthor = transactionAuthor
            let id = try scratchPad.objectId(from: managedIdUrl).get()
            let object = try scratchPad.notDeletedObject(for: id)
            let repoManaged: Model.ManagedModel = try object.asManagedModel()
            try item.updating(managed: repoManaged)
            try scratchPad.save()
            if notTransaction {
                try context.performAndWait {
                    context.transactionAuthor = transactionAuthor
                    try context.save()
                    context.transactionAuthor = nil
                }
            }
            return try Model(managed: repoManaged)
        }
    }
}
