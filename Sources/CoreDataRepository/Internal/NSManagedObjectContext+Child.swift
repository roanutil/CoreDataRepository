// NSManagedObjectContext+Child.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

extension NSManagedObjectContext {
    /// Helper function for error mapping a throwing operation in a temporary context
    @usableFromInline
    func performInChild<Output>(
        schedule: NSManagedObjectContext.ScheduledTaskType = .immediate,
        _ block: @escaping (NSManagedObjectContext) throws -> Output
    ) async -> Result<Output, CoreDataError> {
        let child = childContext()
        let output: Output
        do {
            output = try await child.perform(schedule: schedule) { try block(child) }
        } catch let error as CoreDataError {
            return .failure(error)
        } catch let error as CocoaError {
            return .failure(.cocoa(error))
        } catch let error as NSError {
            return .failure(.unknown(error))
        }
        return .success(output)
    }

    /// Helper function for getting a temporary context
    @usableFromInline
    func childContext() -> NSManagedObjectContext {
        let child = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        child.automaticallyMergesChangesFromParent = true
        child.parent = self
        return child
    }
}
