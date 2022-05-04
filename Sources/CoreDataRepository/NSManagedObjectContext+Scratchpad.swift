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
        promise: @escaping Future<Output, Error>.Promise,
        _ block: @escaping (NSManagedObjectContext) throws -> Void
    ) {
        let scratchPad = scratchPadContext()
        scratchPad.perform {
            do {
                try block(scratchPad)
            } catch {
                scratchPad.rollback()
                promise(.failure(error))
            }
        }
    }

    func performAndWaitInScratchPad<Output>(
        promise: @escaping Future<Output, Error>.Promise,
        _ block: @escaping (NSManagedObjectContext) throws -> Void
    ) throws {
        let scratchPad = scratchPadContext()
        scratchPad.performAndWait {
            do {
                try block(scratchPad)
            } catch {
                scratchPad.rollback()
                promise(.failure(error))
            }
        }
    }

    private func scratchPadContext() -> NSManagedObjectContext {
        let scratchPad = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        scratchPad.automaticallyMergesChangesFromParent = false
        scratchPad.parent = self
        return scratchPad
    }
}
