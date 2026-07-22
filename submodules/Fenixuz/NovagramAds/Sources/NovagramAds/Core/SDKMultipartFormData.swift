import Foundation

/// Minimal `multipart/form-data` builder for the media-upload endpoint. Kept
/// self-contained so the SDK has no third-party dependencies.
struct SDKMultipartFormData: Sendable {
    let boundary: String
    private var parts = Data()

    init(boundary: String = "NovagramAdsBoundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    mutating func addField(name: String, value: String) {
        appendBoundary()
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append(value)
        append("\r\n")
    }

    mutating func addFile(name: String, filename: String, mimeType: String, data: Data) {
        appendBoundary()
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        parts.append(data)
        append("\r\n")
    }

    /// The complete body including the closing boundary.
    func encoded() -> Data {
        var body = parts
        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }

    private mutating func appendBoundary() {
        append("--\(boundary)\r\n")
    }

    private mutating func append(_ string: String) {
        parts.append(Data(string.utf8))
    }
}

/// Best-effort MIME type from a file extension, covering the formats the API
/// accepts for chat-ad media (`jpg|jpeg|png|mp4|mov`).
enum SDKMimeType {
    static func forFilename(_ filename: String) -> String {
        switch (filename as NSString).pathExtension.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        default: return "application/octet-stream"
        }
    }
}
