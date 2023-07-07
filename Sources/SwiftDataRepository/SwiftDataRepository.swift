// SwiftDataRepository.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Foundation
import SwiftData

public actor SwiftDataRepository: ModelActor {
    public let executor: any ModelExecutor

    public init(container: ModelContainer) {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        executor = DefaultModelExecutor(context: context)
    }

    public enum Failure: Error, Equatable, Hashable, Sendable {
        case unknown(NSError)
        case swiftData(SwiftDataError)
        case noPersistentId
        case noModelFoundForId(PersistentIdentifier)

        public var localizedDescription: String {
            switch self {
            case let .unknown(nsError):
                return nsError.localizedDescription
            case let .swiftData(swiftDataError):
                return swiftDataError.localizedDescription
            case .noPersistentId:
                return "PersistentIdentifier required but not found on proxy."
            case let .noModelFoundForId(id):
                return "No model found in context for id \(id.id) and entity \(id.entityName)."
            }
        }
    }

    public func create<Proxy>(_ item: Proxy) async -> Result<Proxy, Failure> where Proxy: PersistentModelProxy {
        await Task {
            do {
                var item = item
                let repoItem = item.asPersistentModel(in: context)
                context.insert(repoItem)
                try context.save()
                item.persistentId = repoItem.objectID
                return .success(item)
            } catch let error as SwiftDataError {
                context.undo()
                return .failure(.swiftData(error))
            } catch {
                context.undo()
                return .failure(.unknown(error as NSError))
            }
        }.value
    }

    public func read<Proxy>(identifier: PersistentIdentifier, as _: Proxy.Type) async -> Result<Proxy, Failure>
        where Proxy: PersistentModelProxy
    {
        await Task {
            guard let repoItem: Proxy.Persistent = context.registeredObject(for: identifier) else {
                return .failure(.noModelFoundForId(identifier))
            }
            return .success(Proxy(persisted: repoItem))
        }.value
    }

    public func update<Proxy>(_ item: Proxy) async -> Result<Proxy, Failure> where Proxy: PersistentModelProxy {
        guard let persistentId = item.persistentId else {
            return .failure(.noPersistentId)
        }
        return await Task {
            guard let object = context.object(with: persistentId) as? Proxy.Persistent else {
                return .failure(.noModelFoundForId(persistentId))
            }
            item.updating(persisted: object)

            do {
                try context.save()
                return .success(Proxy(persisted: object))
            } catch let error as SwiftDataError {
                context.undo()
                return .failure(.swiftData(error))
            } catch {
                context.undo()
                return .failure(.unknown(error as NSError))
            }
        }.value
    }

    public func delete(identifier: PersistentIdentifier) async -> Result<Void, Failure> {
        await Task {
            let object = context.object(with: identifier)
            context.delete(object)
            context.delete(object: object)
            if !object.isDeleted() {
                fatalError()
            }
            do {
                try context.save()
                return .success(())
            } catch let error as SwiftDataError {
                context.undo()
                return .failure(.swiftData(error))
            } catch {
                context.undo()
                return .failure(.unknown(error as NSError))
            }
        }.value
    }
}
