//
//  RepositoryErrors.swift
//  
//
//  Created by Andrew Roan on 1/21/21.
//

import Foundation

public enum RepositoryErrors: Error, Equatable, Hashable {
    case unknown
    case noExistingObjectByID
    case cocoa(NSError)
    case propertyDoesNotMatchEntity
    case entityHasNoProperties
}
