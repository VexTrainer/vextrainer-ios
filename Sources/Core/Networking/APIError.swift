//
//  APIError.swift
//  VexTrainer
//
//  Typed errors thrown by HTTPClient. UI code does:
//      catch APIError.unauthorized { /* show login */ }
//      catch APIError.business(let msg) { /* show msg in toast */ }
//      catch { /* generic */ }
//

import Foundation

enum APIError: LocalizedError {

    /// Underlying URLError — device offline, timeout, DNS failure, etc.
    case network(URLError)

    /// JSON decoding failure. Almost always a DTO/server mismatch — file a bug.
    case decoding(DecodingError)

    /// 4xx or 5xx HTTP response. `message` is the server's explanation if it provided one.
    case http(status: Int, message: String?)

    /// Auth required and refresh attempt also failed. UI should redirect to Login.
    case unauthorized

    /// Server returned 200 OK but `ApiResponse.success == false`. `message` is from the envelope.
    case business(message: String)

    /// 200 OK with `success: true` but `data` was null when the call expected a payload.
    case missingData

    var errorDescription: String? {
        switch self {
        case .network(let urlError):
            return urlError.localizedDescription
        case .decoding:
            return "We couldn't read the server's response. Please try again."
        case .http(let status, let message):
            return message ?? "Server returned status \(status)."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .business(let message):
            return message
        case .missingData:
            return "The server returned an empty response."
        }
    }
}
