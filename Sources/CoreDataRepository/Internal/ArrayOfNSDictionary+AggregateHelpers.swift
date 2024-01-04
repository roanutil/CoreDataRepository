// ArrayOfNSDictionary+AggregateHelpers.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import Foundation

extension [NSDictionary] {
    /// Helper function to convert the result of a CoreData aggregate fetch to a numeric value
    func asAggregateValue<Value>() -> Value? where Value: Numeric {
        ((self as? [[String: Value]]) ?? []).first?.values.first
    }
}
