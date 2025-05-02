// UnmanagedModel.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreData
import Foundation

/// Protocol for a value type that corresponds to an ``NSManagedObject`` subclass
public typealias UnmanagedModel = ReadableUnmanagedModel & WritableUnmanagedModel
