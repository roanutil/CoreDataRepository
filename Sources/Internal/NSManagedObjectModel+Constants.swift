// NSManagedObjectModel+Constants.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData

extension NSManagedObjectModel {
    package nonisolated(unsafe) static let model_UuidId: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [ManagedModel_UuidId.entity()]
        return model
    }()

    package nonisolated(unsafe) static let model_IntId: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [ManagedModel_IntId.entity()]
        return model
    }()
}
