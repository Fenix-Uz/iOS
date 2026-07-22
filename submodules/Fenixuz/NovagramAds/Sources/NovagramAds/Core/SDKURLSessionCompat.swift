import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// Backward-compatibility shim. `URLSession.data(for:)` is iOS 15+ / macOS 12+.
// Consumers that deploy below that (e.g. an iOS 13 host app that vendors these
// sources) call `session.sdkData(for:)` instead, which bridges the classic
// `dataTask` completion API into async/await and forwards Task cancellation.
extension URLSession {
    func sdkData(for request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return try await self.data(for: request)
        }

        let box = SDKURLSessionTaskBox()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
                let task = self.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let data = data, let response = response else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                        return
                    }
                    continuation.resume(returning: (data, response))
                }
                box.store(task)
                task.resume()
            }
        } onCancel: {
            box.cancel()
        }
    }
}

/// Thread-safe holder so the cancellation handler can reach the in-flight task.
private final class SDKURLSessionTaskBox: @unchecked Sendable {
    private let lock = NSLock()
    private var task: URLSessionTask?

    func store(_ task: URLSessionTask) {
        lock.lock(); defer { lock.unlock() }
        self.task = task
    }

    func cancel() {
        lock.lock(); let task = self.task; lock.unlock()
        task?.cancel()
    }
}
