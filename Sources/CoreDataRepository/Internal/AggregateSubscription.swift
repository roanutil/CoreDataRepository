// AggregateSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

/// Subscription provider that sends updates when an aggregate fetch request changes
final class AggregateSubscription<Value>: Subscription<Value, NSDictionary, NSManagedObject> where Value: Numeric {
    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc, subject, request] in
            guard frc.fetchedObjects != nil else {
                self?.start()
                return
            }

            let result: [NSDictionary]
            do {
                result = try frc.managedObjectContext.fetch(request)
            } catch let error as CocoaError {
                subject.send(completion: .failure(.cocoa(error)))
                return
            } catch {
                subject.send(completion: .failure(.unknown(error as NSError)))
                return
            }

            guard let value: Value = result.asAggregateValue() else {
                subject.send(completion: .failure(.fetchedObjectFailedToCastToExpectedType))
                return
            }
            subject.send(value)
        }
    }

    convenience init(
        function: CoreDataRepository.AggregateFunction,
        context: NSManagedObjectContext,
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
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
                context: context
            )
            self.fail(error)
            return
        } catch let error as CocoaError {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context
            )
            self.fail(.cocoa(error))
            return
        } catch {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context
            )
            fail(.unknown(error as NSError))
            return
        }
        guard entityDesc == attributeDesc.entity else {
            self.init(
                fetchRequest: NSFetchRequest(),
                fetchResultControllerRequest: NSFetchRequest(),
                context: context
            )
            fail(.propertyDoesNotMatchEntity)
            return
        }
        self.init(request: request, context: context)
    }

    deinit {
        self.subject.send(completion: .finished)
    }
}
