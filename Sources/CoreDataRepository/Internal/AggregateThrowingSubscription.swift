// AggregateThrowingSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

/// Subscription provider that sends updates when an aggregate fetch request changes
@usableFromInline
final class AggregateThrowingSubscription<Value>: ThrowingSubscription<Value, NSDictionary, NSManagedObject>
    where Value: Numeric
{
    @usableFromInline
    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc, request] in
            guard frc.fetchedObjects != nil else {
                self?.start()
                return
            }

            let result: [NSDictionary]
            do {
                result = try frc.managedObjectContext.fetch(request)
            } catch let error as CocoaError {
                self?.fail(.cocoa(error))
                return
            } catch {
                self?.fail(.unknown(error as NSError))
                return
            }

            guard let value: Value = result.asAggregateValue() else {
                self?.fail(.fetchedObjectFailedToCastToExpectedType)
                return
            }
            self?.send(value)
        }
    }

    @usableFromInline
    convenience init(
        function: CoreDataRepository.AggregateFunction,
        context: NSManagedObjectContext,
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        continuation: AsyncThrowingStream<Value, Error>.Continuation
    ) {
        let request: NSFetchRequest<NSDictionary>
        do {
            request = try NSFetchRequest<NSDictionary>.request(
                function: function,
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy
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
        guard entityDesc == attributeDesc.entity else {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context,
                continuation: continuation
            )
            fail(.propertyDoesNotMatchEntity)
            return
        }
        self.init(request: request, context: context, continuation: continuation)
    }
}
