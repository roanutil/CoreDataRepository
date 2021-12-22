// SubscriptionProvider.swift
// CoreDataRepository
//
//
// MIT License
//
// Copyright © 2021 Andrew Roan

protocol SubscriptionProvider {
    var id: AnyHashable { get }
    func manualFetch()
    func cancel()
    func start()
}
