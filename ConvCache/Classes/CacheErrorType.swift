//
//  CacheErrorType.swift
//  Storage
//
//  Created by 오국원 on 2023/04/06.
//

import Foundation

public enum CacheErrorType: Error {
    case notModified
    case notFound
    case expired
    case forbidden
    case unvailable
    case stale
    case sizeLimitExceeded
    case networkError
    case paymentRequired
}
