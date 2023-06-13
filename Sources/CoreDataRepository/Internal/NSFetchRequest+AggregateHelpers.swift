// NSFetchRequest+AggregateHelpers.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

extension NSFetchRequest<NSDictionary> {
    static func request(
        function: CoreDataRepository.AggregateFunction,
        predicate: NSPredicate,
        entityDesc: NSEntityDescription,
        attributeDesc: NSAttributeDescription,
        groupBy: NSAttributeDescription? = nil
    ) throws -> NSFetchRequest<NSDictionary> {
        guard let entityName = entityDesc.name else {
            throw CoreDataRepositoryError.noEntityNameFound
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

        if let groupBy = groupBy {
            request.propertiesToGroupBy = [groupBy.name]
        }
        request.sortDescriptors = [NSSortDescriptor(key: attributeDesc.name, ascending: false)]
        return request
    }

    static func countRequest(
        predicate: NSPredicate,
        entityDesc: NSEntityDescription
    ) throws -> NSFetchRequest<NSDictionary> {
        guard let attributeDesc = entityDesc.attributesByName.values.first else {
            throw CoreDataRepositoryError.atLeastOneAttributeDescRequired
        }
        return try request(
            function: .count,
            predicate: predicate,
            entityDesc: entityDesc,
            attributeDesc: attributeDesc
        )
    }
}
