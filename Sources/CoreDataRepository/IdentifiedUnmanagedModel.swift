// IdentifiedUnmanagedModel.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData

public protocol IdentifiedUnmanagedModel: ReadableUnmanagedModel {
    associatedtype UnmanagedId: Equatable
    static var unmanagedIdAccessor: (Self) -> UnmanagedId { get }
    /// `NSExpression` for the `unmanagedId` property on `ManagedModel`
    static var unmanagedIdExpression: NSExpression { get }
}

extension IdentifiedUnmanagedModel {
    @inlinable
    public func readManaged(from context: NSManagedObjectContext) throws -> ManagedModel {
        try Self.readManaged(id: Self.unmanagedIdAccessor(self), from: context)
    }

    @inlinable
    public static func readManaged(id: UnmanagedId, from context: NSManagedObjectContext) throws -> ManagedModel {
        let request = Self.managedFetchRequest()
        request.predicate = NSComparisonPredicate(
            leftExpression: Self.unmanagedIdExpression,
            rightExpression: NSExpression(forConstantValue: id),
            modifier: .direct,
            type: .equalTo
        )
        let fetchResult = try context.fetch(request)
        guard let managed = fetchResult.first, fetchResult.count == 1 else {
            throw CoreDataError.noMatchFoundWhenReadingItem
        }
        guard !managed.isDeleted else {
            throw CoreDataError.fetchedObjectIsFlaggedAsDeleted
        }
        return managed
    }
}
