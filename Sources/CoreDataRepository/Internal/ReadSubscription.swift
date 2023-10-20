// ReadSubscription.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import CoreData
import Foundation

final class ReadStreamProvider<Model: UnmanagedModel>: StreamProvider<Model, Model.ManagedModel, Model.ManagedModel> {
    private let objectId: NSManagedObjectID

    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc, request] in
            guard frc.fetchedObjects != nil else {
                self?.start()
                return
            }

            do {
                let result = try frc.managedObjectContext.fetch(request)
                guard let model = result.first, model.objectID == self?.objectId else {
                    fatalError()
                }
                try self?.send(Model(managed: model))
            } catch let error as CocoaError {
                self?.fail(.cocoa(error))
                return
            } catch {
                self?.fail(.unknown(error as NSError))
                return
            }
        }
    }

    init(
        objectId: NSManagedObjectID,
        context: NSManagedObjectContext,
        continuation: AsyncStream<Result<Model, CoreDataError>>.Continuation
    ) {
        self.objectId = objectId
        let fetchRequest = NSFetchRequest<Model.ManagedModel>(entityName: Model.ManagedModel.entity().name!)
        fetchRequest.predicate = NSComparisonPredicate(
            leftExpression: NSExpression(forKeyPath: \NSManagedObject.objectID),
            rightExpression: NSExpression(forConstantValue: objectId),
            modifier: .direct,
            type: .equalTo
        )
        fetchRequest.sortDescriptors = []
        super.init(
            fetchRequest: fetchRequest,
            fetchResultControllerRequest: fetchRequest,
            context: context,
            continuation: continuation
        )
    }

    deinit {
        self.cancel()
    }
}

final class ReadThrowingStreamProvider<Model: UnmanagedModel>: ThrowingStreamProvider<
    Model,
    Model.ManagedModel,
    Model.ManagedModel
> {
    private let objectId: NSManagedObjectID

    override func fetch() {
        frc.managedObjectContext.perform { [weak self, frc, request] in
            guard frc.fetchedObjects != nil else {
                self?.start()
                return
            }

            do {
                let result = try frc.managedObjectContext.fetch(request)
                guard let model = result.first, model.objectID == self?.objectId else {
                    fatalError()
                }
                try self?.send(Model(managed: model))
            } catch let error as CocoaError {
                self?.fail(.cocoa(error))
                return
            } catch {
                self?.fail(.unknown(error as NSError))
                return
            }
        }
    }

    init(
        objectId: NSManagedObjectID,
        context: NSManagedObjectContext,
        continuation: AsyncThrowingStream<Model, Error>.Continuation
    ) {
        self.objectId = objectId
        let fetchRequest = NSFetchRequest<Model.ManagedModel>(entityName: Model.ManagedModel.entity().name!)
        fetchRequest.predicate = NSComparisonPredicate(
            leftExpression: NSExpression(forKeyPath: \NSManagedObject.objectID),
            rightExpression: NSExpression(forConstantValue: objectId),
            modifier: .direct,
            type: .equalTo
        )
        fetchRequest.sortDescriptors = []
        super.init(
            fetchRequest: fetchRequest,
            fetchResultControllerRequest: fetchRequest,
            context: context,
            continuation: continuation
        )
    }

    deinit {
        self.cancel()
    }
}
