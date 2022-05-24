// NSManagedObjectContext+Scratchpad.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

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
