import Foundation

public class ConvCache {
    
    public static let `default` = ConvCache()
    private var cache = Cache()
    
    public init() {
        let size50MB = 52428800
        let size100MB = 104857600
        cache.configureCacheSize(with: size50MB, with: size100MB)
    }
