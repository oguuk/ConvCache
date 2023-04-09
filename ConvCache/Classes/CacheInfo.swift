//
//  CacheInfo.swift
//  Storage
//
//  Created by 오국원 on 2023/04/06.
//

import Foundation

public struct CacheInfo: Codable {
    let etag: String
    let lastRead: Date
    var accessCount: Int = 0
}
