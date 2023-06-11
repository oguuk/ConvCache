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
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
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
    
    private func checkMemory(url: URL) -> CacheableData? {
        guard let cachedData = cache.read(with: url.path) else { return nil }
        updateLastRead(of: url, currentEtag: cachedData.cacheInfo.etag)
        return cachedData
    }
    
    private func checkDisk(url: URL) -> CacheableData? {
        guard let filePath = createDataPath(with: url) else { return nil }
        
        if FileManager.default.fileExists(atPath: filePath.path) {
            guard let data = try? Data(contentsOf: filePath),
                  let cachedData = UserDefaults.standard.data(forKey: url.path),
                  let cachedInfo = self.deserializeCacheDate(data: cachedData) else { return nil }
            
            let cacheableData = CacheableData(cachedData: data, etag: cachedInfo.etag)
            saveIntoCache(url: url, data: cacheableData)
            updateLastRead(of: url, currentEtag: cachedInfo.etag, to: cacheableData.cacheInfo.lastRead)
            
            return cacheableData
        }
        return nil
    }
    
    private func updateLastRead(of url: URL, currentEtag: String, to date: Date = Date()) {
        let updatedCacheInfo = CacheInfo(etag: currentEtag, lastRead: date)
        guard let serializeation = serializeCacheData(cacheInfo: updatedCacheInfo),
              UserDefaults.standard.object(forKey: url.path) != nil else { return }
        
        UserDefaults.standard.set(serializeation, forKey: url.path)
    }
    
    private func saveIntoCache(url: URL, data: CacheableData) {
        cache.saveAtMemoryCache(data: data, with: url.path)
    }
    
    private func saveIntoDiskByLFU(url: URL, data: CacheableData) {
        guard let filePath = createDataPath(with: url) else { return }
        let cacheInfo = CacheInfo(etag: data.cacheInfo.etag, lastRead: Date())
        let targetByteCount = data.cahedData.count
        
        while targetByteCount <= cache.maximumDiskSize, cache.currentDiskSize + targetByteCount > cache.maximumDiskSize {
            let keysAndUsages = UserDefaults.standard.dictionaryRepresentation().compactMap { key, value -> (URL, Int)? in
                guard let cacheInfoData = value as? Data,
                      let cacheInfoValue = deserializeCacheDate(data: cacheInfoData) else { return nil }
                return (URL(fileURLWithPath: key), cacheInfoValue.accessCount)
            }
            
            guard let targetKey = keysAndUsages.min(by: { $0.1 < $1.1})?.0 else { break }
            deleteFromDisk(URLStr: "\(targetKey)")
        }
        
        guard let encoded = serializeCacheData(cacheInfo: cacheInfo) else { return }
        UserDefaults.standard.set(encoded, forKey: url.path)
        FileManager.default.createFile(atPath: filePath.path, contents: data.cahedData, attributes: nil)
        cache.updateCurrentDiskSize(with: targetByteCount)
    }
    
    private func saveIntoDiskByLRU(url: URL, data: CacheableData) {
        guard let filePath = self.createDataPath(with: url) else { return }
        
        let cacheInfo = CacheInfo(etag: data.cacheInfo.etag, lastRead: Date())
        let targetByteCount = data.cahedData.count

        while targetByteCount <= cache.maximumDiskSize
                && cache.currentDiskSize + targetByteCount > cache.maximumDiskSize {
            var removeTarget: (url: String, minTime: Date) = ("", Date())
            
            UserDefaults.standard.dictionaryRepresentation().forEach({ key, value in
                guard let cacheInfoData = value as? Data,
                      let cacheInfoValue = self.deserializeCacheDate(data: cacheInfoData) else { return }
                
                if removeTarget.minTime > cacheInfoValue.lastRead {
                    removeTarget = (key, cacheInfoValue.lastRead)
                }
            })
            deleteFromDisk(URLStr: "\(removeTarget.url)")
        }
        
        if cache.currentDiskSize + targetByteCount <= cache.maximumDiskSize {
            guard let encoded = serializeCacheData(cacheInfo: cacheInfo) else { return }
            UserDefaults.standard.set(encoded, forKey: url.path)
            FileManager.default.createFile(atPath: filePath.path, contents: data.cahedData, attributes: nil)
            cache.updateCurrentDiskSize(with: targetByteCount)
        }
    }
    
    private func deleteFromDisk(URLStr: String) {
        
        guard let dataURL = URL(string: URLStr),
              let filePath = createDataPath(with: dataURL),
              let targetFileAttribute = try? FileManager.default.attributesOfItem(atPath: filePath.path) else { return }
        
        let targetByteCount = targetFileAttribute[FileAttributeKey.size] as? Int ?? 0
        
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
            UserDefaults.standard.removeObject(forKey: dataURL.path)
            cache.updateCurrentDiskSize(with: targetByteCount * -1)
        } catch {
            return
        }
    }
    
    private func serializeCacheData(cacheInfo: CacheInfo) -> Data? {
        let data = try? JSONEncoder().encode(cacheInfo)
        return data
    }
    
    private func deserializeCacheDate(data: Data) -> CacheInfo? {
        let cacheInfo = try? JSONDecoder().decode(CacheInfo.self, from: data)
        return cacheInfo
    }
    
    private func createDataPath(with url: URL) -> URL? {
        guard let path = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else { return nil }
        let dataDirectoryPath = path.appendingPathComponent("Storage")
        let filePath = dataDirectoryPath.appendingPathComponent(url.pathComponents.joined(separator: "-"))
        if !FileManager.default.fileExists(atPath: dataDirectoryPath.path) {
            try? FileManager.default.createDirectory(
                atPath: dataDirectoryPath.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        return filePath
    }
}


