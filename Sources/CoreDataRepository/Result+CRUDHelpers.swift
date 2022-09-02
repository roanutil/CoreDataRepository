// Result+CRUDHelpers.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2022 Andrew Roan

import CoreData
import Foundation

extension Result where Success == NSManagedObjectID, Failure == Error {
    func mapToNSManagedObject(context: NSManagedObjectContext) -> Result<NSManagedObject, Error> {
        flatMap { objectId -> Result<NSManagedObject, Error> in
            Result<NSManagedObject, Error> {
                try context.notDeletedObject(for: objectId)
            }
        }
    }
}

extension Result where Success == NSManagedObject, Failure == Error {
    func map<T>(to _: T.Type) -> Result<T, Error>
        where T: RepositoryManagedModel
    {
        flatMap { object -> Result<T, Error> in
            Result<T, Error> {
                try object.asRepoManaged()
            }
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

extension Result where Failure == Error {
    func mapToRepoError() -> Result<Success, CoreDataRepositoryError> {
        mapError { error in
            if let repoError = error as? CoreDataRepositoryError {
                return repoError
            } else {
                return .coreData(error as NSError)
            }
        }
    }
}
