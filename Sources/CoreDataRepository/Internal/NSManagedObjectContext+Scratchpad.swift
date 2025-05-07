// NSManagedObjectContext+Scratchpad.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

extension NSManagedObjectContext {
    @usableFromInline
    func performInScratchPad<Output>(
        schedule: NSManagedObjectContext.ScheduledTaskType = .immediate,
        _ block: @escaping (NSManagedObjectContext) throws -> Output
    ) async -> Result<Output, CoreDataError> {
        let scratchPad = scratchPadContext()
        let output: Output
        do {
            output = try await scratchPad.perform(schedule: schedule) { try block(scratchPad) }
        } catch let error as CoreDataError {
            await scratchPad.perform(schedule: schedule) {
                scratchPad.reset()
            }
            await scratchPad.parent?.perform(schedule: schedule) {
                scratchPad.parent?.rollback()
            }
            return .failure(error)
        } catch let error as CocoaError {
            await scratchPad.perform(schedule: schedule) {
                scratchPad.reset()
            }
            await scratchPad.parent?.perform(schedule: schedule) {
                scratchPad.parent?.rollback()
            }
            return .failure(.cocoa(error))
        } catch {
            await scratchPad.perform(schedule: schedule) {
                scratchPad.reset()
            }
            await scratchPad.parent?.perform(schedule: schedule) {
                scratchPad.parent?.rollback()
            }
            return .failure(CoreDataError.unknown(error as NSError))
        }
        return .success(output)
    }

    private func scratchPadContext() -> NSManagedObjectContext {
        let scratchPad = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        scratchPad.automaticallyMergesChangesFromParent = false
        scratchPad.parent = self
        return scratchPad
    }
}
