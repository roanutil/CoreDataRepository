// CoreDataRepository+BatchRequest.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData

extension CoreDataRepository {
    /// Execute a `NSBatchDeleteRequest` against the store.
    @inlinable
    public func delete(
        _ request: NSBatchDeleteRequest,
        transactionAuthor: String? = nil
    ) async -> Result<NSBatchDeleteResult, CoreDataError> {
        let context = Transaction.current?.context ?? context
        return await context.performInScratchPad { [context] scratchPad in
            context.transactionAuthor = transactionAuthor
            guard let result = try scratchPad.execute(request) as? NSBatchDeleteResult else {
                context.transactionAuthor = nil
                throw CoreDataError.fetchedObjectFailedToCastToExpectedType
            }
            context.transactionAuthor = nil
            return result
        }
    }

    /// Execute a `NSBatchInsertRequest` against the store
    @inlinable
    public func insert(
        _ request: NSBatchInsertRequest,
        transactionAuthor: String? = nil
    ) async -> Result<NSBatchInsertResult, CoreDataError> {
        let context = Transaction.current?.context ?? context
        return await context.performInScratchPad { [context] scratchPad in
            context.transactionAuthor = transactionAuthor
            guard let result = try scratchPad.execute(request) as? NSBatchInsertResult else {
                context.transactionAuthor = nil
                throw CoreDataError.fetchedObjectFailedToCastToExpectedType
            }
            context.transactionAuthor = nil
            return result
        }
    }

    /// Execute a NSBatchUpdateRequest against the store.
    @inlinable
    public func update(
        _ request: NSBatchUpdateRequest,
        transactionAuthor: String? = nil
    ) async -> Result<NSBatchUpdateResult, CoreDataError> {
        let context = Transaction.current?.context ?? context
        return await context.performInScratchPad { [context] scratchPad in
            context.transactionAuthor = transactionAuthor
            guard let result = try scratchPad.execute(request) as? NSBatchUpdateResult else {
                context.transactionAuthor = nil
                throw CoreDataError.fetchedObjectFailedToCastToExpectedType
            }
            context.transactionAuthor = nil
            return result
        }
    }
}
