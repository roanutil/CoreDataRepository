// NSManagedObjectContext+Child.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

extension NSManagedObjectContext {
    func performInChild<Output>(
        schedule: NSManagedObjectContext.ScheduledTaskType = .immediate,
        _ block: @escaping (NSManagedObjectContext) throws -> Output
    ) async -> Result<Output, CoreDataRepositoryError> {
        let child = childContext()
        let output: Output
        do {
            output = try await child.perform(schedule: schedule) { try block(child) }
        } catch let error as CoreDataRepositoryError {
            return .failure(error)
        } catch let error as NSError {
            return .failure(.coreData(error))
        }
        return .success(output)
    }

    func childContext() -> NSManagedObjectContext {
        let child = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        child.automaticallyMergesChangesFromParent = true
        child.parent = self
        return child
    }
}
