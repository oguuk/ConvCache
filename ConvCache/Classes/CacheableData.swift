//
//  CacheableData.swift
//  Storage
//
//  Created by 오국원 on 2023/04/05.
//

import Foundation

public class CacheableData {
    let cahedData: Data
    let cacheInfo: CacheInfo
    
    public init(cachedData: Data, etag: String) {
        self.cahedData = cachedData
        self.cacheInfo = CacheInfo(etag: etag, lastRead: Date())
    }
}
