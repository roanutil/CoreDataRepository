// CoreDataBatchError.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation

/// An error that models the failure of a single item in a batch operation.
public struct CoreDataBatchError<T>: Error {
    public let item: T
    public let error: CoreDataError

    public var localizedDescription: String {
        error.localizedDescription
    }

    public init(item: T, error: CoreDataError) {
        self.item = item
        self.error = error
    }
}

extension CoreDataBatchError: Equatable where T: Equatable {}

extension CoreDataBatchError: Hashable where T: Hashable {}

extension CoreDataBatchError: Sendable where T: Sendable {}
