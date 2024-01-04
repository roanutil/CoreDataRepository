// FileCabinetsView.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2024 Andrew Roan

import CoreData
import CoreDataRepository
import Foundation
import Observation
import SwiftUI

struct FileCabinetsView: View {
    let viewModel: FileCabinetsViewModel

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
            Button(
                action: {
                    Task {
                        await viewModel.newFileCabinet()
                    }
                },
                label: {
                    Text("+")
                }
            )
            List {
                ForEach(viewModel.state.fileCabinets) { fileCabinet in
                    Text(fileCabinet.id.uuidString)
                        .onTapGesture {
                            Task {
                                await viewModel.select(fileCabinet: fileCabinet)
                            }
                        }
                }
            }
            .refreshable(action: viewModel.loadFileCabinets)
        }
    }

    @ViewBuilder @MainActor
    private func content() -> some View {
        if let detailViewModel = viewModel.detailViewModel {
            FileCabinetDetailView(viewModel: detailViewModel)
        }
    }

    @ViewBuilder @MainActor
    private func detail() -> some View {
        EmptyView()
    }
}

struct FileCabinetsState: Hashable, Sendable {
    var fileCabinets: [FileCabinet] = []
}

@Observable
final class FileCabinetsViewModel {
    @ObservationIgnored
    let repository: CoreDataRepository
    var state: FileCabinetsState
    var detailViewModel: FileCabinetDetailViewModel?

    @Sendable
    func newFileCabinet() async {
        switch await repository.create(FileCabinet(id: UUID(), drawers: [])) {
        case let .success(fileCabinet):
            state.fileCabinets.append(fileCabinet)
        case let .failure(error):
            print(error.localizedDescription)
            return
        }
    }

    @Sendable
    func loadFileCabinets() async {
        switch await repository.fetch(Self.fetchRequest, as: FileCabinet.self) {
        case let .success(success):
            state.fileCabinets = success
        case let .failure(error):
            print(error.localizedDescription)
        }
    }

    @Sendable
    func select(fileCabinet: FileCabinet) async {
        let detail = FileCabinetDetailViewModel(
            repository: repository,
            state: FileCabinetDetailState(fileCabinet: fileCabinet)
        )
        detailViewModel = detail
        await detail.refreshFileCabinet()
    }

    private static let fetchRequest: NSFetchRequest<FileCabinet.Managed> = {
        let request = FileCabinet.managedFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \(FileCabinet.Managed).id, ascending: true)]
        return request
    }()

    init(
        repository: CoreDataRepository,
        state: FileCabinetsState = FileCabinetsState(),
        detailViewModel: FileCabinetDetailViewModel? = nil
    ) {
        self.repository = repository
        self.state = state
        self.detailViewModel = detailViewModel
    }
}
