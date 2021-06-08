//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 30.05.2021.
//

import Foundation
import PureduxSideEffects

extension TimeEventsOperator {
    public struct Request: OperatorRequest {
        public let id: UUID
        public let delay: Double
        public let completeHandler: (TaskResult<Void, Void>) -> Void

        public init(id: UUID, delay: Double, completeHandler: @escaping (TaskResult<Void, Void>) -> Void) {
            self.id = id
            self.delay = delay
            self.completeHandler = completeHandler
        }

        public func handle(_ result: TaskResult<Void, Void>) {
            completeHandler(result)
        }
    }
}

public final class TimeEventsOperator: Operator<TimeEventsOperator.Request, DispatchWorkItem> {
    public override init(label: String = "Time-Events-Operator",
                  qos: DispatchQoS = .utility,
                  logger: Logger = .console(.info)) {
        super.init(label: label, qos: qos, logger: logger)
    }

    public override func run(task: DispatchWorkItem, for request: Request) {
        processingQueue.asyncAfter(deadline: .now() + request.delay, execute: task)
    }

    public override func createTaskFor(_ request: TimeEventsOperator.Request,
                                with completeHandler: @escaping (TaskResult<Void, Void>) -> Void) -> DispatchWorkItem {

        DispatchWorkItem {
            completeHandler(.success(Void()))
        }
    }
}
