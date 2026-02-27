// NSFetchRequest+AggregateHelpers.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

extension NSFetchRequest<NSDictionary> {
    /// Helper function for building an aggregate fetch request
    @usableFromInline
    static func request(
        function: CoreDataRepository.AggregateFunction,
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
    ) throws(CoreDataError) -> NSFetchRequest<NSDictionary> {
        guard let entityName = entityDesc.name else {
            throw CoreDataError.noEntityNameFound
        }
        let expDesc = NSExpressionDescription.aggregate(function: function, attributeDesc: attributeDesc)
        let request = NSFetchRequest<NSDictionary>(entityName: entityName)
        request.predicate = predicate
        request.entity = entityDesc
        request.returnsObjectsAsFaults = false
        request.resultType = .dictionaryResultType
        if function != .count {
            request.propertiesToFetch = [expDesc]
        }

        if let groupBy {
            request.propertiesToGroupBy = [groupBy.name]
        }
        request.sortDescriptors = [NSSortDescriptor(key: attributeDesc.name, ascending: false)]
        return request
    }

    /// Helper function for building a count fetch request
    @usableFromInline
    static func countRequest(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription
    ) throws(CoreDataError) -> NSFetchRequest<NSDictionary> {
        guard let attributeDesc = entityDesc.attributesByName.values.first else {
            throw CoreDataError.atLeastOneAttributeDescRequired
        }
        return try request(
            function: .count,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc
        )
    }
}
