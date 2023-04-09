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
