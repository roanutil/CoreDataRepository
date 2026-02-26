// CountThrowingSubscription.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

@preconcurrency import CoreData
import Foundation

/// Subscription provider that sends updates when a count fetch request changes
@usableFromInline
final class CountThrowingSubscription<Value: Numeric & Sendable>: ThrowingSubscription<
    Value,
    NSDictionary,
    NSManagedObject
>,
    @unchecked Sendable
{
    @usableFromInline
    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc, request] in
            if (frc.fetchedObjects ?? []).isEmpty {
                self?.start()
            }
            do {
                let count = try frc.managedObjectContext.count(for: request)
                self?.send(Value(exactly: count) ?? Value.zero)
            } catch let error as CocoaError {
                self?.fail(.cocoa(error))
            } catch {
                self?.fail(CoreDataError.unknown(error as NSError))
            }
        }
    }

    @usableFromInline
    convenience init(
        context: NSManagedObjectContext,
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        continuation: AsyncThrowingStream<Value, any Error>.Continuation
    ) {
        let request: NSFetchRequest<NSDictionary>
        do {
            request = try NSFetchRequest.countRequest(
                predicate: predicate,
                entityDesc: entityDesc
            )
        } catch {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context,
                continuation: continuation
            )
            fail(error)
            return
        }
        self.init(request: request, context: context, continuation: continuation)
    }

    @usableFromInline
    convenience init(
        context: NSManagedObjectContext,
        predicate: NSPredicate,
        changeTrackingRequest: NSFetchRequest<NSManagedObject>,
        entityDesc: NSEntityDescription,
        continuation: AsyncThrowingStream<Value, any Error>.Continuation
    ) {
        let request: NSFetchRequest<NSDictionary>
        do {
            request = try NSFetchRequest.countRequest(
                predicate: predicate,
                entityDesc: entityDesc
            )
        } catch {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context,
                continuation: continuation
            )
            fail(error)
            return
        }
        self.init(
            fetchRequest: request,
            fetchResultControllerRequest: changeTrackingRequest,
            context: context,
            continuation: continuation
        )
    }
}
