// NSManagedObjectContext+Scratchpad.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CoreData
import Foundation

extension NSManagedObjectContext {
    func performInScratchPad<Output>(
        promise: @escaping Future<Output, CoreDataRepositoryError>.Promise,
        _ block: @escaping (NSManagedObjectContext) -> Result<Output, CoreDataRepositoryError>
    ) {
        let scratchPad = scratchPadContext()
        scratchPad.perform {
            let result = block(scratchPad)
            if case .failure = result {
                scratchPad.rollback()
            }
            promise(result)
        }
    }

    func performInScratchPad<Output>(
        schedule: NSManagedObjectContext.ScheduledTaskType = .immediate,
        _ block: @escaping (NSManagedObjectContext) throws -> Output
    ) async -> Result<Output, CoreDataRepositoryError> {
        let scratchPad = scratchPadContext()
        let output: Output
        do {
            output = try await scratchPad.perform(schedule: schedule) { try block(scratchPad) }
        } catch let error as CoreDataRepositoryError {
            await scratchPad.perform {
                scratchPad.rollback()
            }
            return .failure(error)
        } catch let error as NSError {
            await scratchPad.perform {
                scratchPad.rollback()
            }
            return .failure(CoreDataRepositoryError.coreData(error))
        }
        return .success(output)
    }

    func performAndWaitInScratchPad<Output>(
        promise: @escaping Future<Output, CoreDataRepositoryError>.Promise,
        _ block: @escaping (NSManagedObjectContext) -> Result<Output, CoreDataRepositoryError>
    ) throws {
        let scratchPad = scratchPadContext()
        scratchPad.performAndWait {
            let result = block(scratchPad)
            if case .failure = result {
                scratchPad.rollback()
            }
            promise(result)
        }
    }

    private func scratchPadContext() -> NSManagedObjectContext {
        let scratchPad = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        scratchPad.automaticallyMergesChangesFromParent = false
        scratchPad.parent = self
        return scratchPad
    }
}
