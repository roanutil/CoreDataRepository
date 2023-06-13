// ArrayOfNSDictionary+AggregateHelpers.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation

extension [NSDictionary] {
    func asAggregateValue<Value>() -> Value? where Value: Numeric {
        ((self as? [[String: Value]]) ?? []).first?.values.first
    }
}
