// CoreDataRepository+Aggregate.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CoreData

extension CoreDataRepository {
    // MARK: Count

    /// Get the count or quantity of managed object instances that satisfy the predicate.
    public func count<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> {
        await context.performInScratchPad { scratchPad in
            do {
                let request = try NSFetchRequest<NSDictionary>
                    .countRequest(predicate: predicate, entityDesc: entityDesc)
                let count = try scratchPad.count(for: request)
                return Value(exactly: count) ?? Value.zero
            } catch let error as CocoaError {
                throw CoreDataError.cocoa(error)
            } catch {
                throw CoreDataError.unknown(error as NSError)
            }
        }
    }

    /// Subscribe to the count or quantity of managed object instances that satisfy the predicate.
    public func countSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
        CountSubscription(
            context: context.childContext(),
            predicate: predicate,
            entityDesc: entityDesc
        ).stream()
    }

    /// Subscribe to the count or quantity of managed object instances that satisfy the predicate.
    public func countThrowingSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
        CountSubscription(
            context: context.childContext(),
            predicate: predicate,
            entityDesc: entityDesc
        ).throwingStream()
    }

    // MARK: Sum

    /// Get the sum of a managed object's numeric property for all instances that satisfy the predicate.
    public func sum<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> {
        await Self.send(
            function: .sum,
            context: context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the sum of a managed object's numeric property for all instances that satisfy the predicate.
    public func sumSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
        AggregateSubscription(
            function: .sum,
            context: context.childContext(),
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        ).stream()
    }

    /// Subscribe to the sum of a managed object's numeric property for all instances that satisfy the predicate.
    public func sumThrowingSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
        AggregateSubscription(
            function: .sum,
            context: context.childContext(),
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        ).throwingStream()
    }

    // MARK: Average

    /// Get the average of a managed object's numeric property for all instances that satisfy the predicate.
    public func average<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> {
        await Self.send(
            function: .average,
            context: context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the average of a managed object's numeric property for all instances that satisfy the predicate.
    public func averageSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
        AggregateSubscription(
            function: .average,
            context: context.childContext(),
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        ).stream()
    }

    /// Subscribe to the average of a managed object's numeric property for all instances that satisfy the predicate.
    public func averageThrowingSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
        AggregateSubscription(
            function: .average,
            context: context.childContext(),
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        ).throwingStream()
    }

    // MARK: Min

    /// Get the min or minimum of a managed object's numeric property for all instances that satisfy the predicate.
    public func min<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> {
        await Self.send(
            function: .min,
            context: context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the min or minimum of a managed object's numeric property for all instances that satisfy the
    /// predicate.
    public func minSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
        AggregateSubscription(
            function: .min,
            context: context.childContext(),
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        ).stream()
    }

    /// Subscribe to the min or minimum of a managed object's numeric property for all instances that satisfy the
    /// predicate.
    public func minThrowingSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
        AggregateSubscription(
            function: .min,
            context: context.childContext(),
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        ).throwingStream()
    }

    // MARK: Max

    /// Get the max or maximum of a managed object's numeric property for all instances that satisfy the predicate.
    public func max<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) async -> Result<Value, CoreDataError> {
        await Self.send(
            function: .max,
            context: context,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
    }

    /// Subscribe to the max or maximum of a managed object's numeric property for all instances that satisfy the
    /// predicate.
    public func maxSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncStream<Result<Value, CoreDataError>> {
        AggregateSubscription(
            function: .max,
            context: context.childContext(),
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        ).stream()
    }

    /// Subscribe to the max or maximum of a managed object's numeric property for all instances that satisfy the
    /// predicate.
    public func maxThrowingSubscription<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil,
        as _: Value.Type
    ) -> AsyncThrowingStream<Value, Error> {
        AggregateSubscription(
            function: .max,
            context: context.childContext(),
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        ).throwingStream()
    }

    // MARK: Internals

    enum AggregateFunction: String {
        case count
        case sum
        case average
        case min
        case max
    }

    private static func aggregate<Value: Numeric>(
        context: NSManagedObjectContext,
        request: NSFetchRequest<NSDictionary>
    ) throws -> Value {
        let result = try context.fetch(request)
        guard let value: Value = result.asAggregateValue() else {
            throw CoreDataError.fetchedObjectFailedToCastToExpectedType
        }
        return value
    }

    private static func send<Value>(
        function: AggregateFunction,
        context: NSManagedObjectContext,
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
    ) async -> Result<Value, CoreDataError> where Value: Numeric {
        guard entityDesc == attributeDesc.entity else {
            return .failure(.propertyDoesNotMatchEntity)
        }
        return await context.performInScratchPad { scratchPad in
            let request = try NSFetchRequest<NSDictionary>.request(
                function: function,
                predicate: predicate,
                entityDesc: entityDesc,
                attributeDesc: attributeDesc,
                groupBy: groupBy
            )
            do {
                let value: Value = try Self.aggregate(context: scratchPad, request: request)
                return value
            } catch let error as CocoaError {
                throw CoreDataError.cocoa(error)
            } catch {
                throw CoreDataError.unknown(error as NSError)
            }
        }
    }
}
