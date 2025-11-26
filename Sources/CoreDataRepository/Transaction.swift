// Transaction.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData

/// A context where all contained operations are atomic. If any operation fails, all the operation fails.
/// If the transaction is canceled, all operations fail.
public final class Transaction: @unchecked Sendable {
    @usableFromInline
    let context: NSManagedObjectContext
    /// Only mutated from within ``context``'s `DispatchQueue`
    @usableFromInline
    var canceled: Bool

    /// Removes all changes made so far.
    @inlinable
    public func cancel() {
        context.performAndWait {
            context.reset()
            context.parent?.performAndWait {
                context.parent?.rollback()
            }
            self.canceled = true
        }
    }

    @TaskLocal public static var current: Transaction?

    @usableFromInline
    init(context: NSManagedObjectContext) {
        self.context = context
        canceled = false
    }
}
