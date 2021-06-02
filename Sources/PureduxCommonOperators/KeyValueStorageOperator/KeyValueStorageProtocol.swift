//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 30.05.2021.
//

import Foundation

protocol KeyValueStorageProtocol {

    func remove(for key: String)

    func removeAll()

    func write<T>(state: T, for key: String) where T: Encodable

    func read<T>(with key: String) -> T?  where T: Decodable
}
