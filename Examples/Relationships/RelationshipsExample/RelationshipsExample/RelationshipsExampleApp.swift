// RelationshipsExampleApp.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

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
