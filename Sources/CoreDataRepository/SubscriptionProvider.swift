//
//  File.swift
//  
//
//  Created by Andrew Roan on 1/25/21.
//

public protocol SubscriptionProvider {
    var id: AnyHashable { get }
    func manualFetch()
    func cancel()
}
