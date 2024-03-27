// CountThrowingSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

/// Subscription provider that sends updates when a count fetch request changes
@usableFromInline
final class CountThrowingSubscription<Value>: ThrowingSubscription<Value, NSDictionary, NSManagedObject>
    where Value: Numeric
{
    @usableFromInline
    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc] in
            if (frc.fetchedObjects ?? []).isEmpty {
                self?.start()
            }
            do {
                let count = try frc.managedObjectContext.count(for: frc.fetchRequest)
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
        continuation: AsyncThrowingStream<Value, Error>.Continuation
    ) {
        let request: NSFetchRequest<NSDictionary>
        do {
            request = try NSFetchRequest<NSDictionary>.countRequest(
                predicate: predicate,
                entityDesc: entityDesc
            )
        } catch let error as CoreDataError {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context,
                continuation: continuation
            )
            self.fail(error)
            return
        } catch let error as CocoaError {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context,
                continuation: continuation
            )
            self.fail(.cocoa(error))
            return
        } catch {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context,
                continuation: continuation
            )
            fail(.unknown(error as NSError))
            return
        }
        self.init(request: request, context: context, continuation: continuation)
    }
}
