// NSManagedObjectContext+Child.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

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
        } catch {
            return .failure(.unknown(error as NSError))
        }
        return .success(output)
    }

    /// Helper function for error mapping a throwing operation in a temporary context
    @usableFromInline
    func performInChildAndWait<Output>(
        schedule _: NSManagedObjectContext.ScheduledTaskType = .immediate,
        _ block: @escaping (NSManagedObjectContext) throws -> Output
    ) -> Result<Output, CoreDataError> {
        let child = childContext()
        let output: Output
        do {
            output = try child.performAndWait { try block(child) }
        } catch let error as CoreDataError {
            return .failure(error)
        } catch let error as CocoaError {
            return .failure(.cocoa(error))
        } catch {
            return .failure(.unknown(error as NSError))
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
