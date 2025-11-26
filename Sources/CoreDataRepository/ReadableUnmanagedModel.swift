// ReadableUnmanagedModel.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

/// Protocol for a value type for reading a ``NSManagedObject`` subclass
///
/// There are times where a single ``NSManagedObject``subclass may be accessed via multiple value types.
/// ``ReadableUnmanagedModel`` provides a minimal interface for fetching and reading values from CoreData
/// without other functionality.
///
/// For example, for `ManagedMovie`, there are two unmanaged models, `Movie` and `MoviePlaceholder`.
/// `MoviePlaceholder` will never create, update, or delete a corresponding instance of `ManagedMovie`.
/// It is read only.
/// `Movie` supports all operations against a corresponding instacnce of `ManagedMovie`.
///
/// ```swift
/// @objc(ManagedMovie)
/// final class ManagedMovie: NSManagedObject {
///     @NSManaged var id: UUID
///     @NSManaged var title: String
/// }
///
/// struct Movie: Hashable, UnmanagedModel {
///     let id: UUID
///     var title: String = ""
///
///     init(managed: ManagedMovie) throws {
///         self.init(
///             id: managed.id,
///             title: managed.title
///         )
///     }
///
///     func asManagedModel(in context: NSManagedObjectContext) throws -> ManagedMovie {
///         let object = ManagedMovie(context: context)
///         object.id = id
///         object.title = title
///         return object
///     }
///
///     func updating(managed: ManagedMovie) throws {
///         managed.id = id
///         managed.title = title
///     }
/// }
///
/// struct MoviePlaceholder: ReadableUnmanagedModel {
///     let id: UUID
///
///     init(managed: ManagedMovie) throws {
///         self.init(id: managed.id)
///     }
///
///     func readManaged(from context: NSManagedObjectContext) throws -> ManagedMovie {
///         let request = Self.managedFetchRequest()
///             request.predicate = NSComparisonPredicate(
///             leftExpression: NSExpression(forKeyPath: \ManagedMovie.id,
///             rightExpression: NSExpression(forConstantValue: id),
///             modifier: .direct,
///             type: .equalTo
///         )
///         let fetchResult = try context.fetch(request)
///         guard let managed = fetchResult.first, fetchResult.count == 1 else {
///             throw CoreDataError.noMatchFoundWhenReadingItem
///         }
///         return managed
///     }
/// }
/// ```
public protocol ReadableUnmanagedModel: FetchableUnmanagedModel {
    func readManaged(from context: NSManagedObjectContext) throws -> ManagedModel
}

extension ReadableUnmanagedModel where Self: ManagedIdReferencable {
    @inlinable
    public func readManaged(from context: NSManagedObjectContext) throws -> ManagedModel {
        guard let managedId else {
            throw CoreDataError.noObjectIdOnItem
        }
        return try context.notDeletedObject(for: managedId).asManagedModel()
    }
}

extension ReadableUnmanagedModel where Self: ManagedIdUrlReferencable {
    @inlinable
    public func readManaged(from context: NSManagedObjectContext) throws -> ManagedModel {
        guard let managedIdUrl else {
            throw CoreDataError.noUrlOnItemToMapToObjectId
        }
        let managedId = try context.objectId(from: managedIdUrl).get()
        return try context.notDeletedObject(for: managedId).asManagedModel()
    }
}
