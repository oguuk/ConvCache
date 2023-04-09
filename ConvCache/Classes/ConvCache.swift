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
    
    private func get(URLStr: String, etag: String? = nil, completion: @escaping (Result<CacheableData, Error>) -> Void) {
        guard let url = URL(string: URLStr) else { return completion(.failure(CacheErrorType.networkError)) }
        var request = URLRequest(url: url)
        
        if let etag = etag {
            request.addValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(CacheErrorType.networkError))
                return
            }
            
            guard let data = data else {
                completion(.failure(CacheErrorType.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200..<300:
                let etag = httpResponse.allHeaderFields["Etag"] as? String ?? ""
                let data = CacheableData(cachedData: data, etag: etag)
                self.saveIntoCache(url: url, data: data)
                self.saveIntoDiskByLRU(url: url, data: data)
                completion(.success(data))
            case 304:
                completion(.failure(CacheErrorType.notModified))
            case 402:
                completion(.failure(CacheErrorType.paymentRequired))
            default:
                completion(.failure(CacheErrorType.networkError))
            }
        }
        
        task.resume()
    }
