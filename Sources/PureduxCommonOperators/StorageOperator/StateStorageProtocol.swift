//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 30.05.2021.
//

import Foundation

public protocol StateStorageProtocol {
    associatedtype State: Codable
    associatedtype MetaData

    func write(state: State) throws -> MetaData
    func read() throws -> State?
}
