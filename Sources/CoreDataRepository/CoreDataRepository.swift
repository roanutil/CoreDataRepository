// CoreDataRepository.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

/// A wrapper around CoreData that improves the ergonomics and safety of using CoreData.
///
/// CoreDataRepository only exposes value types that bridge to the internal ``NSManagedObject``
/// sub-classes. This makesit a lot easier to use CoreData asynchronously. ``NSManagedObject``s
/// are not thread safe and are not simple Swift classes.
///
/// CRUD, batch CRUD, fetch, and aggregate operations are available.
///
/// For batch operations, there are options that use ``NSBatchInsertRequest``, ``NSBatchUpdateRequest``, and
/// ``NSBatchDeleteRequest`` in
/// addition to non-atomic options that individually perform the operation on each item.
///
/// For fetch and aggregate operations, there are additional subscription and throwing subscription options.
/// Subscriptions return an ``AsyncStream`` of
/// ``Result``s with strongly typed errors. Throwing subscriptions return an ``AsyncThrowingStream``.
///
/// All uses of ``context`` are wrapped in `perform` or `performAndWait` blocks so ``CoreDataRepository`` is concurrency
/// safe.
public final class CoreDataRepository: @unchecked Sendable {
    /// CoreData context the repository uses. A child or 'scratch' context is usually created from this context for work
    /// to be performed in.
    public let context: NSManagedObjectContext

    /// Executes a block of code within a Core Data transaction so that all contained
    /// operations either suceed or fail.
    ///
    /// - Important: When performing operations within a transaction,
    ///   the `transactionAuthor` is applied to the final context save operation, not to individual
    ///   requests. This means the transaction author will be recorded in the persistent
    ///   history for the entire transaction. Any `transactionAuthor` parameters for operations
    ///   in the transaction will be ignored.
    ///
    /// - Important: Batch request operations within a transaction fail to record `transactionAuthor`.
    ///   Hopefully, this can be fixed in the future but no workaround is available now.
    ///
    /// - Important: Crossing any boundary that breaks `TaskLocal` continuity will disconnect from the transaction
    ///   unless it is continued in a new ``withTransaction(continuing:transactionAuthor:_:)``.
    ///   For example, any operations performed in`Task.detached` or a `DispatchQueue` must be wrapped in
    ///   a new `withTransaction(continuing: transaction) { ... }`.
    ///
    /// - Parameters:
    ///   - continuing: Use an existing ``Transaction`` after crossing a `Task` boundary.
    ///   - transactionAuthor: An optional string to identify the author of this transaction
    ///     in Core Data's persistent history tracking.
    ///   - block: The code block to execute within the transaction context.
    /// - Returns: The result of the block execution.
    /// - Throws: ``CoreDataError`` if the transaction fails.
    @inlinable
    public func withTransaction<T, E>(
        continuing existingTransaction: Transaction? = nil,
        transactionAuthor: String? = nil,
        _ block: (Transaction) async throws(E) -> T
    ) async throws(CoreDataError) -> T where E: Error {
        let transaction = existingTransaction ?? Transaction(context: context.scratchPadContext())
        let scratchPad = transaction.context
        return try await CoreDataError.catching {
            try await Transaction.$current.withValue(transaction) {
                let result = try await block(transaction)
                // An existing transaction will handle all saving in its original `withTransaction`
                guard existingTransaction == nil else {
                    return result
                }
                try scratchPad.performAndWait {
                    guard scratchPad.hasChanges else {
                        return
                    }
                    guard !transaction.canceled else {
                        scratchPad.reset()
                        return
                    }
                    do {
                        try scratchPad.save()
                    } catch {
                        scratchPad.reset()
                        throw error
                    }
                }
                try context.performAndWait {
                    guard context.hasChanges else {
                        return
                    }
                    guard !transaction.canceled else {
                        context.rollback()
                        return
                    }
                    context.transactionAuthor = transactionAuthor
                    do {
                        try context.save()
                        context.transactionAuthor = nil
                    } catch {
                        context.transactionAuthor = nil
                        context.rollback()
                        throw error
                    }
                }
                return result
            }
        }
    }

    @inlinable
    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}
