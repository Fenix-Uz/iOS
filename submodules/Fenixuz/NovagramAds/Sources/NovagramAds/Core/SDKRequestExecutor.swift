import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The lowest transport layer: turns an ``SDKEndpoint`` into a `URLRequest`,
/// runs it on the injected `URLSession`, and returns the raw bytes plus the
/// `HTTPURLResponse`. It does **not** interpret status codes, inject/refresh
/// tokens, or retry — those live one layer up in ``SDKHTTPClient``. Keeping this
/// piece dumb lets ``SDKAuthProvider`` reuse it for the token endpoints without
/// creating a dependency cycle.
struct SDKRequestExecutor: Sendable {
    let configuration: SDKConfiguration
    let session: URLSession

    func perform(_ endpoint: SDKEndpoint, accessToken: String?) async throws -> (Data, HTTPURLResponse) {
        let request = try buildRequest(for: endpoint, accessToken: accessToken)
        do {
            let (data, response) = try await session.sdkData(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw SDKError.invalidResponse
            }
            return (data, http)
        } catch let error as SDKError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError {
            if urlError.code == .cancelled {
                throw CancellationError()
            }
            throw SDKError.transport(message: urlError.localizedDescription)
        } catch {
            throw SDKError.transport(message: error.localizedDescription)
        }
    }

    private func buildRequest(for endpoint: SDKEndpoint, accessToken: String?) throws -> URLRequest {
        let url = try endpoint.url(relativeTo: configuration.baseURL)
        var request = URLRequest(url: url, timeoutInterval: configuration.timeout)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        for (key, value) in configuration.extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if endpoint.requiresAuth, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Ad-serving endpoints (show/click) also need the server-to-server key.
        if endpoint.sendsApiKey, let apiKey = configuration.apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }

        switch endpoint.body {
        case .json(let data):
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
        case .raw(let data, let contentType):
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = data
        case nil:
            break
        }

        return request
    }
}
