//
//  ApiResponse.swift
//  VexTrainer
//
//  Matches the server's response envelope, e.g.:
//      {
//        "success": true,
//        "data": { ... },
//        "message": "Login successful",
//        "resultCode": 0
//      }
//
//  Every API call (except direct content fetches for markdown) is wrapped in this.
//

import Foundation

struct ApiResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String
    let resultCode: Int
}

/// Sentinel type for endpoints that return no meaningful payload (logout, mark-read, etc.).
/// Equivalent to Kotlin's `safeApiCallUnit` pattern but expressed in the type system.
struct EmptyResponse: Decodable {}
