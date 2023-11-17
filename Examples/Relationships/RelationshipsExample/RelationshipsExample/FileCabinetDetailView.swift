// FileCabinetDetailView.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import CoreDataRepository
import Foundation
import Observation
import SwiftUI

struct FileCabinetDetailView: View {
    let viewModel: FileCabinetDetailViewModel

    var body: some View {
        Section {
            List(viewModel.state.fileCabinet.drawers) { drawer in
                Text(drawer.id.uuidString)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.delete(drawer: drawer)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
            }
            .refreshable(action: viewModel.refreshFileCabinet)
        } header: {
            HStack {
                Text("Drawers")
                Button(
                    action: {
                        Task {
                            await viewModel.newDrawer()
                        }
                    },
                    label: {
                        Image(systemName: "plus")
                            .padding()
                    }
                )
            }
        }
        .navigationTitle("File Cabinet \(viewModel.state.fileCabinet.id.uuidString)")
    }
}

struct FileCabinetDetailState: Hashable, Sendable {
    var fileCabinet: FileCabinet
}

@Observable
final class FileCabinetDetailViewModel {
    @ObservationIgnored
    let repository: CoreDataRepository
    var state: FileCabinetDetailState

    @Sendable
    func newDrawer() async {
        var newFileCabinet = state.fileCabinet
        newFileCabinet.drawers.append(FileCabinet.Drawer(id: UUID(), documents: []))
        switch await repository.update(newFileCabinet.managedIdUrl!, with: newFileCabinet) {
        case let .success(success):
            state.fileCabinet = success
        case let .failure(error):
            print(error.localizedDescription)
            return
        }
    }

    @Sendable
    func refreshFileCabinet() async {
        let result: Result<FileCabinet, CoreDataError> = await repository.read(
            state.fileCabinet.managedIdUrl!,
            of: FileCabinet.self
        )
        switch result {
        case let .success(success):
            state.fileCabinet = success
        case let .failure(error):
            print(error.localizedDescription)
        }
    }
    
    @Sendable
    func delete(drawer: FileCabinet.Drawer) async {
        guard let url = drawer.managedIdUrl else {
            return
        }
        switch await repository.delete(url) {
        case .success:
            return
        case let .failure(error):
            print("Failed to delete drawer \(drawer.id.uuidString): \(error.localizedDescription)")
        }
    }

    private static let fetchRequest: NSFetchRequest<FileCabinet.Managed> = {
        let request = FileCabinet.Managed.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \(FileCabinet.Managed).id, ascending: true)]
        return request
    }()

    init(repository: CoreDataRepository, state: FileCabinetDetailState) {
        self.repository = repository
        self.state = state
    }
}
