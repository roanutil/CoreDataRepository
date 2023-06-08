// PersistentModelProxy.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation
import SwiftData

public protocol PersistentModelProxy: Equatable {
    associatedtype Persistent: PersistentModel

    var persistentId: PersistentIdentifier? { get set }
    func asPersistentModel(in context: ModelContext) -> Persistent
    init(persisted: Persistent)
    func updating(persisted: Persistent)
}
