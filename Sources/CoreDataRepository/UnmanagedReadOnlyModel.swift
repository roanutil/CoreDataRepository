// UnmanagedReadOnlyModel.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import Foundation

/// Protocol for a value type for reading and fetchiing a ``NSManagedObject`` subclass
///
/// There are times where a single ``NSManagedObject``subclass may be accessed via multiple value types.
/// ``UnmanagedReadOnlyModel`` provides a minimal interface for reading and fetching values from CoreData
/// without needing to implement the full ``UnmanagedModel`` protocol.
///
/// For example, for `ManagedMovie`, there are two unmanaged models, `Movie` and `MoviePlaceholder`.
/// `MoviePlaceholder` will never create, update, or delete a corresponding instance of `ManagedMovie`. It is read only.
/// `Movie` supports all operations against a corresponding instacnce of `ManagedMovie`.
///
/// ```swift
/// @objc(ManagedMovie)
/// final class ManagedMovie: NSManagedObject {
///     @NSManaged var id: UUID?
///     @NSManaged var title: String?
/// }
///
/// struct Movie: Hashable, UnmanagedModel {
///     let id: UUID
///     var title: String = ""
///     var url: URL?
///
///     init(managed: ManagedMovie) throws {
///         self.init(
///             id: managed.id!,
///             title: managed.title!,
///             url: managed.objectID.uriRepresentation()
///         )
///     }
///
///     var managedIdUrl: URL? {
///         get {
///             url
///         }
///         set(newValue) {
///             url = newValue
///         }
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
/// struct MoviePlaceholder: UnmanagedReadOnlyModel {
///     let id: UUID
///
///     init(managed: ManagedMovie) throws {
///         self.init(id: managed.id!)
///     }
/// }
/// ```
public protocol UnmanagedReadOnlyModel: Equatable {
    /// The ``NSManagedObject`` subclass `Self` corresponds to
    associatedtype ManagedModel: NSManagedObject

    /// Initialize of new instance of `Self` from an instance of ``ManagedModel``
    init(managed: ManagedModel) throws

    /// ``NSFetchRequest`` for ``ManagedModel`` with a strongly typed ``NSFetchRequest.ResultType``
    static func managedFetchRequest() -> NSFetchRequest<ManagedModel>
}

extension UnmanagedReadOnlyModel {
    @inlinable
    public static func managedFetchRequest() -> NSFetchRequest<ManagedModel> {
        NSFetchRequest<ManagedModel>(
            entityName: ManagedModel.entity().name ?? ManagedModel.entity()
                .managedObjectClassName
        )
    }
}
