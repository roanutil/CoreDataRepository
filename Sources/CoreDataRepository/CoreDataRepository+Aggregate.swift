// CoreDataRepository+Aggregate.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import Combine
import CoreData

extension CoreDataRepository {
    // MARK: Types

    /// The aggregate function to be calculated
    public enum AggregateFunction: String {
        case count
        case sum
        case average
        case min
        case max
    }

    // MARK: Private Functions

    private func request(
        function: AggregateFunction,
        predicate _: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
    ) -> NSFetchRequest<NSDictionary> {
        let expDesc = NSExpressionDescription.aggregate(function: function, attributeDesc: attributeDesc)
        let request = NSFetchRequest<NSDictionary>(entityName: entityDesc.managedObjectClassName)
        request.entity = entityDesc
        request.returnsObjectsAsFaults = false
        request.resultType = .dictionaryResultType
        if function == .count {
            request.propertiesToFetch = [attributeDesc.name, expDesc]
        } else {
            request.propertiesToFetch = [expDesc]
        }

        if let groupBy = groupBy {
            request.propertiesToGroupBy = [groupBy.name]
        }
        request.sortDescriptors = [NSSortDescriptor(key: attributeDesc.name, ascending: false)]
        return request
    }

    /// Calculates aggregate values
    /// - Parameters
    ///     - function: Function
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    ///     - attributeDesc: NSAttributeDescription
    ///     - groupBy: NSAttributeDescription? = nil
    /// - Returns
    ///     - `[[String: Value]]`
    ///
    private static func aggregate<Value: Numeric>(
        context: NSManagedObjectContext,
        request: NSFetchRequest<NSDictionary>
    ) throws -> [[String: Value]] {
        let result = try context.fetch(request)
        return result as? [[String: Value]] ?? []
    }

    private static func send<Value>(
        context: NSManagedObjectContext,
        request: NSFetchRequest<NSDictionary>
    ) -> AnyPublisher<[[String: Value]], Error> where Value: Numeric {
        Deferred { [context] in Future { [context] promise in
            context.performInScratchPad(promise: promise) { scratchPad in
                do {
                    let result: [[String: Value]] = try Self.aggregate(context: scratchPad, request: request)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }}.eraseToAnyPublisher()
    }

    // MARK: Public Functions

    /// Calculate the count for a fetchRequest
    /// - Parameters:
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    /// - Returns
    ///     - AnyPublisher<Success<Int>, Error>
    ///
    public func count<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription
    ) -> AnyPublisher<[[String: Value]], Error> {
        Deferred { [context] in Future { [context] promise in
            let _request = NSFetchRequest<NSDictionary>(entityName: entityDesc.name ?? "")
            _request.predicate = predicate
            _request
                .sortDescriptors =
                [NSSortDescriptor(key: entityDesc.attributesByName.values.first!.name, ascending: true)]
            context.performInScratchPad(promise: promise) { scratchPad in
                do {
                    let count = try scratchPad.count(for: _request)
                    promise(.success([["countOf\(entityDesc.name ?? "")": Value(exactly: count) ?? Value.zero]]))
                } catch {
                    promise(.failure(error))
                }
            }
        }}.eraseToAnyPublisher()
    }

    /// Calculate the sum for a fetchRequest
    /// - Parameters:
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    ///     - attributeDesc: NSAttributeDescription
    ///     - groupBy: NSAttributeDescription? = nil
    /// - Returns
    ///     - AnyPublisher<Success<Value>, Error>
    ///
    public func sum<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
    ) -> AnyPublisher<[[String: Value]], Error> {
        let _request = request(
            function: .sum,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: AggregateRepositoryFailure(code: .propertyDoesNotMatchEntity, method: .sum))
                .eraseToAnyPublisher()
        }
        return Self.send(context: context, request: _request)
    }

    /// Calculate the average for a fetchRequest
    /// - Parameters:
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    ///     - attributeDesc: NSAttributeDescription
    ///     - groupBy: NSAttributeDescription? = nil
    /// - Returns
    ///     - AnyPublisher<Success<Value>, Error>
    ///
    public func average<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
    ) -> AnyPublisher<[[String: Value]], Error> {
        let _request = request(
            function: .average,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: AggregateRepositoryFailure(code: .unknown, method: .average))
                .eraseToAnyPublisher()
        }
        return Self.send(context: context, request: _request)
    }

    /// Calculate the min for a fetchRequest
    /// - Parameters:
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    ///     - attributeDesc: NSAttributeDescription
    ///     - groupBy: NSAttributeDescription? = nil
    /// - Returns
    ///     - AnyPublisher<Success<Value>, Error>
    ///
    public func min<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
    ) -> AnyPublisher<[[String: Value]], Error> {
        let _request = request(
            function: .min,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: AggregateRepositoryFailure(code: .propertyDoesNotMatchEntity, method: .min))
                .eraseToAnyPublisher()
        }
        return Self.send(context: context, request: _request)
    }

    /// Calculate the max for a fetchRequest
    /// - Parameters:
    ///     - predicate: NSPredicate
    ///     - entityDesc: NSEntityDescription
    ///     - attributeDesc: NSAttributeDescription
    ///     - groupBy: NSAttributeDescription? = nil
    /// - Returns
    ///     - AnyPublisher<Success<Value>, Error>
    ///
    public func max<Value: Numeric>(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
    ) -> AnyPublisher<[[String: Value]], Error> {
        let _request = request(
            function: .max,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc,
            groupBy: groupBy
        )
        guard entityDesc == attributeDesc.entity else {
            return Fail(error: AggregateRepositoryFailure(code: .unknown, method: .max))
                .eraseToAnyPublisher()
        }
        return Self.send(context: context, request: _request)
    }
}

// MARK: Extensions

extension NSExpression {
    /// Convenience initializer for NSExpression that represent an aggregate function on a keypath
    fileprivate convenience init(
        function: CoreDataRepository.AggregateFunction,
        attributeDesc: NSAttributeDescription
    ) {
        let keyPathExp = NSExpression(forKeyPath: attributeDesc.name)
        self.init(forFunction: "\(function.rawValue):", arguments: [keyPathExp])
    }
}

extension NSExpressionDescription {
    /// Convenience initializer for NSExpressionDescription that represent the properties to fetch in NSFetchRequest
    fileprivate static func aggregate(
        function: CoreDataRepository.AggregateFunction,
        attributeDesc: NSAttributeDescription
    ) -> NSExpressionDescription {
        let expression = NSExpression(function: function, attributeDesc: attributeDesc)
        let expDesc = NSExpressionDescription()
        expDesc.expression = expression
        expDesc.name = "\(function.rawValue)Of\(attributeDesc.name.capitalized)"
        expDesc.expressionResultType = attributeDesc.attributeType
        return expDesc
    }
}
