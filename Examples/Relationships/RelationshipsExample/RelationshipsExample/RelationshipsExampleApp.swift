// RelationshipsExampleApp.swift
// CoreDataRepository
//
// This source code is licensed under the MIT License (MIT) found in the
// LICENSE file in the root directory of this source tree.

import CoreDataRepository
import SwiftUI

@main
struct RelationshipsExampleApp: App {
    let fileCabinetsViewModel =
        FileCabinetsViewModel(repository: CoreDataRepository(
            context: CoreDataStack.persistentContainer()
                .newBackgroundContext()
        ))

    var body: some Scene {
        WindowGroup {
            FileCabinetsView(viewModel: fileCabinetsViewModel)
        }
    }
}
