// AggregateSubscription.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

@preconcurrency import CoreData
import Foundation

/// Subscription provider that sends updates when an aggregate fetch request changes
@usableFromInline
final class AggregateSubscription<Value: Numeric & Sendable>: Subscription<Value, NSDictionary, NSManagedObject>,
    @unchecked Sendable
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
                self?.fail(.fetchedObjectFailedToCastToExpectedType(description: nil))
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
        continuation: AsyncStream<Result<Value, CoreDataError>>.Continuation
    ) {
        let request: NSFetchRequest<NSDictionary>
        do {
            request = try NSFetchRequest.request(
                function: function,
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy
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
        guard entityDesc == attributeDesc.entity else {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context,
                continuation: continuation
            )
            guard let entityName = entityDesc.name ?? entityDesc.managedObjectClassName else {
                fail(.propertyDoesNotMatchEntity(description: nil))
                return
            }
            guard let attributeEntityName = attributeDesc.entity.name ?? attributeDesc.entity.managedObjectClassName
            else {
                fail(.propertyDoesNotMatchEntity(description: entityName))
                return
            }
            fail(
                .propertyDoesNotMatchEntity(
                    description: "\(entityName) != \(attributeDesc.name).\(attributeEntityName)"
                )
            )
            return
        }
        self.init(request: request, context: context, continuation: continuation)
    }

    @usableFromInline
    convenience init(
        function: CoreDataRepository.AggregateFunction,
        context: NSManagedObjectContext,
        predicate: NSPredicate,
        changeTrackingRequest: NSFetchRequest<NSManagedObject>,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        continuation: AsyncStream<Result<Value, CoreDataError>>.Continuation
    ) {
        let request: NSFetchRequest<NSDictionary>
        do {
            request = try NSFetchRequest.request(
                function: function,
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy
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
        guard entityDesc == attributeDesc.entity else {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context,
                continuation: continuation
            )
            guard let entityName = entityDesc.name ?? entityDesc.managedObjectClassName else {
                fail(.propertyDoesNotMatchEntity(description: nil))
                return
            }
            guard let attributeEntityName = attributeDesc.entity.name ?? attributeDesc.entity.managedObjectClassName
            else {
                fail(.propertyDoesNotMatchEntity(description: entityName))
                return
            }
            fail(
                .propertyDoesNotMatchEntity(
                    description: "\(entityName) != \(attributeDesc.name).\(attributeEntityName)"
                )
            )
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
