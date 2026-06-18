//
//  Endpoint.swift
//  VexTrainer
//
//  Value type describing one HTTP request. Each feature defines its own endpoint
//  factories as static extensions, keeping request construction local to the feature
//  while sharing the same transport plumbing.
//
//  Example:
//      extension Endpoint {
//          static func login(_ req: LoginRequest) -> Endpoint {
//              Endpoint(path: "/Auth/login", method: .post, body: req, requiresAuth: false)
//          }
//      }
//

import Foundation

struct Endpoint {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }

    let path: String
    let method: Method
    let queryItems: [URLQueryItem]
    let body: (any Encodable)?
    let requiresAuth: Bool

    init(
        path: String,
        method: Method = .get,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.requiresAuth = requiresAuth
    }
}
