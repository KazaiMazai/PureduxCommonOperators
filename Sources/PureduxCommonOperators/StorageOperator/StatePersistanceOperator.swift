//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 30.05.2021.
//

import Foundation
import PureduxSideEffects

extension StatePersistanceOperator {
    public struct Request<State: Codable, MetaData>: OperatorRequest {
        public func handle(_ result: TaskResult<MetaData, Void>) {
            handler(result)
        }

        public init(id: UUID,
                    state: State,
                    handler: @escaping (TaskResult<MetaData, Void>) -> Void) {
            self.id = id
            self.state = state
            self.handler = handler
        }

        public let id: UUID
        public let state: State
        public let handler: (TaskResult<MetaData, Void>) -> Void
    }
}

public final class StatePersistanceOperator<StateStorage, State, MetaData>:
    Operator<StatePersistanceOperator.Request<State, MetaData>, DispatchWorkItem>

    where
    StateStorage: StateStorageProtocol,
    StateStorage.State == State,
    StateStorage.MetaData == MetaData {

    private let workerQueue: DispatchQueue
    private let storage: StateStorage

    public init(storage: StateStorage,
                workerQueue: DispatchQueue = DispatchQueue(label: "State-Persistance-Operator-worker"),
                label: String = "State-Persistance-Operator",
                qos: DispatchQoS = .background,
                logger: Logger = .with(label: "State-Persistance-Operator", logger: .console(.info))) {
        self.storage = storage
        self.workerQueue = workerQueue
        super.init(label: label, qos: qos, logger: logger)
    }

    public override func run(task: DispatchWorkItem, for request: StatePersistanceOperator.Request<State, MetaData>) {
        workerQueue.async(execute: task)
    }

    public override func createTaskFor(
        _ request: StatePersistanceOperator.Request<State, MetaData>,
        with completeHandler: @escaping (TaskResult<MetaData, Void>) -> Void) -> DispatchWorkItem {

        DispatchWorkItem { [weak self] in
            guard let self = self else {
                return
            }

            do {
                let metaData = try self.storage.write(state: request.state)
                completeHandler(.success(metaData))
            } catch {
                completeHandler(.failure(error))
            }
        }
    }
}
