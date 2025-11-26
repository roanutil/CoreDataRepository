// ArrayOfNSDictionary+AggregateHelpers.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import Foundation

extension [NSDictionary] {
    /// Helper function to convert the result of a CoreData aggregate fetch to a numeric value
    func asAggregateValue<Value>() -> Value? where Value: Numeric {
        ((self as? [[String: Value]]) ?? []).first?.values.first
    }
}
