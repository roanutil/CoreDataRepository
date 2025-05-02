// NSExpression+AggregateHelpers.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

extension NSExpression {
    /// Convenience initializer for NSExpression that represent an aggregate function on a keypath
    convenience init(
        function: CoreDataRepository.AggregateFunction,
        attributeDesc: NSAttributeDescription
    ) {
        let keyPathExp = NSExpression(forKeyPath: attributeDesc.name)
        self.init(forFunction: "\(function.rawValue):", arguments: [keyPathExp])
    }
}

extension NSExpressionDescription {
    /// Convenience initializer for NSExpressionDescription that represent the properties to fetch in NSFetchRequest
    static func aggregate(
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
