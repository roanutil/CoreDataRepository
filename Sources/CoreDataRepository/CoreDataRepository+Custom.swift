// CoreDataRepository+Custom.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

extension CoreDataRepository {
    /// Escape hatch method for performing arbitrary operations inside a 'scratchpad' `NSManagedObjectContext` where
    /// changes will be discarded if not saved.
    ///
    /// The caller is responsible for saving the contexts and cleaning up if needed.
    /// All this  method provides is the contexts and mapping `Error` into ``CoreDataError``.
    @inlinable
    public func custom<T>(
        schedule: NSManagedObjectContext.ScheduledTaskType = .enqueued,
        block: @escaping (
            _ parentContext: NSManagedObjectContext,
            _ scratchPadContext: NSManagedObjectContext
        ) throws -> T
    ) async -> Result<T, CoreDataError> {
        await context.performInScratchPad(schedule: schedule) { [context] scratchPad in try block(context, scratchPad) }
    }
}
