// CoreDataRepository+Fetch.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2023 Andrew Roan

import Combine
import CoreData

extension CoreDataRepository {
    /// Fetch items from the store with a ``NSFetchRequest``.
    public func fetch<Model: UnmanagedModel>(_ request: NSFetchRequest<Model.ManagedModel>) async
        -> Result<[Model], CoreDataError>
    {
        await context.performInChild { fetchContext in
            try fetchContext.fetch(request).map(Model.init(managed:))
        }
    }

    /// Fetch items from the store with a ``NSFetchRequest`` and receive updates as the store changes.
    public func fetchSubscription<Model: UnmanagedModel>(
        _ request: NSFetchRequest<Model.ManagedModel>,
        of _: Model.Type
    ) -> AsyncStream<Result<[Model], CoreDataError>> {
        FetchSubscription(request: request, context: context.childContext()).stream()
    }

    /// Fetch items from the store with a ``NSFetchRequest`` and receive updates as the store changes.
    public func fetchThrowingSubscription<Model: UnmanagedModel>(
        _ request: NSFetchRequest<Model.ManagedModel>,
        of _: Model.Type
    ) -> AsyncThrowingStream<[Model], Error> {
        FetchSubscription(request: request, context: context.childContext()).throwingStream()
    }
}
