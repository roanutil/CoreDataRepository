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
        NavigationSplitView(
            sidebar: sidebar,
            content: content,
            detail: detail
        )
    }

    @ViewBuilder @MainActor
    private func sidebar() -> some View {
        VStack {
            Text(viewModel.state.fileCabinet.id.uuidString)
            Button(
                action: {
                    Task {
                        await viewModel.newDrawer()
                    }
                },
                label: {
                    Text("+")
                }
            )
            List {
                ForEach(viewModel.state.fileCabinet.drawers) { drawer in
                    Text(drawer.id.uuidString)
                }
            }
            .refreshable(action: viewModel.refreshFileCabinet)
        }
    }

    @ViewBuilder @MainActor
    private func content() -> some View {
        EmptyView()
    }

    @ViewBuilder @MainActor
    private func detail() -> some View {
        EmptyView()
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

    private static let fetchRequest: NSFetchRequest<FileCabinet.Managed> = {
        let request = FileCabinet.managedFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \(FileCabinet.Managed).id, ascending: true)]
        return request
    }()

    init(repository: CoreDataRepository, state: FileCabinetDetailState) {
        self.repository = repository
        self.state = state
    }
}
