//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 30.05.2021.
//

import Foundation
import PureduxSideEffects

extension KeyValueStorageOperator {
    struct Request<Value> {
        let id: UUID
        let taskType: TaskType<Value>
        let handler: (TaskResult<Value?, Void>) -> Void
    }

    enum TaskType<Value> {
        case write(key: String, value: Value)
        case read(key: String)
    }
}

extension KeyValueStorageOperator.Request: OperatorRequest {
    public func handle(_ result: TaskResult<Value?, Void>) {
        handler(result)
    }
}

final class KeyValueStorageOperator<Storage, Value: Codable>: Operator<KeyValueStorageOperator.Request<Value>,
                                                                           DispatchWorkItem>

    where
    Storage: KeyValueStorageProtocol {

    private let workerQeueue: DispatchQueue
    private let storage: Storage

    public init(
        storage: Storage,
        workerQeueue: DispatchQueue = DispatchQueue(label: "Secured-Storage-Operator-worker"),
        label: String = "Secured-Storage-Operator",
        qos: DispatchQoS = .background,
        logger: Logger = .with(label: "State-Persistance-Operator", logger: .console(.info))) {

        self.storage = storage
        self.workerQeueue = workerQeueue
        super.init(label: label, qos: qos, logger: logger)
    }

    override func run(task: DispatchWorkItem, for request: KeyValueStorageOperator.Request<Value>) {
        workerQeueue.async(execute: task)
    }

    override func createTaskFor(
        _ request: KeyValueStorageOperator.Request<Value>,
        with completeHandler: @escaping (TaskResult<Value?, Void>) -> Void) -> DispatchWorkItem {

        DispatchWorkItem { [weak self] in
            switch request.taskType {
            case .write(key: let key, value: let value):
                self?.storage.write(state: value, for: key)
                completeHandler(.success(value))
            case .read(key: let key):
                let maybeValue: Value? = self?.storage.read(with: key)
                guard let value = maybeValue else {
                    completeHandler(.failure(Errors.notFound))
                    return
                }

                completeHandler(.success(value))
            }
        }
    }
}

extension KeyValueStorageOperator {
    enum Errors: Error {
        case notFound

        var localizedDescription: String {
            switch self {
            case .notFound:
                return "Value not found"
            }
        }
    }
}
