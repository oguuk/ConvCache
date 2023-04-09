//
//  Cache.swift
//  Pods-Storage_Example
//
//  Created by 오국원 on 2023/04/08.
//

import Foundation

public struct Cache {
    
    private(set) var maximumDiskSize: Int = 0
    private(set) var currentDiskSize: Int = 0
    private var cache = NSCache<NSString, CacheableData>()
    
    mutating func configureCacheSize(with maximumMemoryBytes: Int, with maximumDiskBytes: Int) {
        cache.totalCostLimit = maximumMemoryBytes
        maximumDiskSize = maximumDiskBytes
        // currentDiskSize
    }
    
    mutating func saveAtMemoryCache(data: CacheableData, with key: String) {
        let forKey = NSString(string: key)
        cache.setObject(data, forKey: forKey, cost: data.cahedData.count)
    }
