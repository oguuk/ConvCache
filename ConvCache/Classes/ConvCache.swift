import Foundation

public class ConvCache {
    
    public static let `default` = ConvCache()
    private var cache = Cache()
    
    public init() {
        let size50MB = 52428800
        let size100MB = 104857600
        cache.configureCacheSize(with: size50MB, with: size100MB)
    }
    
    public func configureCache(with maximumMemoryBytes: Int, with maximumDiskBytes: Int) {
        cache.configureCacheSize(with: maximumMemoryBytes, with: maximumDiskBytes)
    }
    
    public func setData(URLStr: String, completion: @escaping (Result<Data,Error>) -> Void) {
        guard let url = URL(string: URLStr) else { return completion(.failure(CacheErrorType.networkError)) }
        
        // NSCache 확인
        if let data = self.checkMemory(url: url) {
            get(URLStr: "\(url)", etag: data.cacheInfo.etag) { (result) in
                switch result  {
                case let .success(cacheableData):
                    completion(.success(cacheableData.cahedData))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
            return
        }
        
        if let data = self.checkDisk(url: url) {
            get(URLStr: "\(url)", etag: data.cacheInfo.etag) { (result) in
                switch result {
                case let .success(cacheableData):
                    completion(.success(cacheableData.cahedData))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
        
        get(URLStr: "\(url)") { result in
            switch result {
            case let .success(cacheableData):
                completion(.success(cacheableData.cahedData))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
