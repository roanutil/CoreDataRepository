// FileCabinetsView.swift
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

struct FileCabinetsView: View {
    let viewModel: FileCabinetsViewModel

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar()
        } content: {
            content()
        } detail: {
            detail()
        }
    }

    @ViewBuilder @MainActor
    private func sidebar() -> some View {
        List(viewModel.state.fileCabinets) { fileCabinet in
            Text(fileCabinet.id.uuidString)
                .onTapGesture {
                    Task {
                        await viewModel.select(fileCabinet: fileCabinet)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.delete(fileCabinet: fileCabinet)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
        }
        .refreshable(action: viewModel.loadFileCabinets)
        .toolbar {
            Button(
                action: {
                    Task {
                        await viewModel.newFileCabinet()
                    }
                },
                label: {
                    Image(systemName: "plus")
                        .padding()
                }
            )
        }
        .navigationTitle("File Cabinets")
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
    
    @Sendable
    func delete(fileCabinet: FileCabinet) async {
        guard let url = fileCabinet.managedIdUrl else {
            return
        }
        switch await repository.delete(url) {
        case .success:
            return
        case let .failure(error):
            print("Failed to delete file cabinet \(fileCabinet.id.uuidString): \(error.localizedDescription)")
        }
    }

    private static let fetchRequest: NSFetchRequest<FileCabinet.Managed> = {
        let request = FileCabinet.Managed.fetchRequest()
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
