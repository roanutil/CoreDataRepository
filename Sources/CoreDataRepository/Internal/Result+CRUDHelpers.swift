// Result+CRUDHelpers.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

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

extension Result where Failure == CoreDataError {
    func save(context: NSManagedObjectContext) -> Result<Success, CoreDataError> {
        flatMap { success in
            do {
                try context.save()
                if let parentContext = context.parent {
                    var result: Result<Success, CoreDataError> = .success(success)
                    parentContext.performAndWait {
                        do {
                            try parentContext.save()
                        } catch let error as CocoaError {
                            result = .failure(.cocoa(error))
                        } catch {
                            result = .failure(.unknown(error as NSError))
                        }
                    }
                    return result
                }
                return .success(success)
            } catch let error as CocoaError {
                return .failure(.cocoa(error))
            } catch {
                return .failure(.unknown(error as NSError))
            }
        }
    }
}

extension Result where Failure == Error {
    func mapToRepoError() -> Result<Success, CoreDataError> {
        mapError { error in
            if let repoError = error as? CoreDataError {
                return repoError
            } else if let cocoaError = error as? CocoaError {
                return .cocoa(cocoaError)
            } else {
                return .unknown(error as NSError)
            }
        }
    }
}
