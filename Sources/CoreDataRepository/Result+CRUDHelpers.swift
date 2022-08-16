// Result+CRUDHelpers.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import CoreData
import Foundation

extension Result where Success == NSManagedObjectID, Failure == CoreDataRepositoryError {
    func mapToNSManagedObject(context: NSManagedObjectContext) -> Result<NSManagedObject, CoreDataRepositoryError> {
        flatMap { objectId in
            do {
                let object: NSManagedObject = try context.existingObject(with: objectId)
                guard !object.isDeleted else {
                    return .failure(.fetchedObjectIsFlaggedAsDeleted)
                }
                return .success(object)
            } catch {
                return .failure(.coreData(error as NSError))
            }
        }
    }
}

extension Result where Success == NSManagedObject, Failure == CoreDataRepositoryError {
    func map<T>(to _: T.Type) -> Result<T, CoreDataRepositoryError>
        where T: RepositoryManagedModel
    {
        flatMap { _object in
            guard let object = _object as? T else {
                return .failure(.fetchedObjectFailedToCastToExpectedType)
            }
            return .success(object)
        }
    }
}

extension Result where Failure == CoreDataRepositoryError {
    func save(context: NSManagedObjectContext) -> Result<Success, CoreDataRepositoryError> {
        flatMap { success in
            do {
                try context.save()
                if let parentContext = context.parent {
                    var result: Result<Success, CoreDataRepositoryError> = .success(success)
                    parentContext.performAndWait {
                        do {
                            try parentContext.save()
                        } catch {
                            result = .failure(.coreData(error as NSError))
                        }
                    }
                    return result
                }
                return .success(success)
            } catch {
                return .failure(.coreData(error as NSError))
            }
        }
    }
}
