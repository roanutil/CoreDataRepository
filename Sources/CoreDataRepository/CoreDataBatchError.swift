// CoreDataBatchError.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation

/// An error that models the failure of a single item in a batch operation.
///
/// Batch operations that do not use `NSBatch*Request` are not atomic. Some operations may succeed while others fail. If
/// multiple errors are returned, it would
/// be helpful if each error is associated with the input data for the operation.
public struct CoreDataBatchError<T>: Error {
    /// The input data used for the batched operation. Usually an ``UnmanagedModel`` instance or URL encoded
    /// NSManagedObjectID.
    public let item: T

    /// The underlying error.
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
