// NSManagedObjectContext+Scratchpad.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

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
            await scratchPad.perform {
                scratchPad.rollback()
            }
            return .failure(error)
        } catch let error as CocoaError {
            await scratchPad.perform {
                scratchPad.rollback()
            }
            return .failure(.cocoa(error))
        } catch let error as NSError {
            await scratchPad.perform {
                scratchPad.rollback()
            }
            return .failure(CoreDataError.unknown(error))
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
