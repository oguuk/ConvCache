# ConvCache

[![CI Status](https://img.shields.io/travis/oguuk/ConvCache.svg?style=flat)](https://travis-ci.org/oguuk/ConvCache)
[![Version](https://img.shields.io/cocoapods/v/ConvCache.svg?style=flat)](https://cocoapods.org/pods/ConvCache)
[![License](https://img.shields.io/cocoapods/l/ConvCache.svg?style=flat)](https://cocoapods.org/pods/ConvCache)
[![Platform](https://img.shields.io/cocoapods/p/ConvCache.svg?style=flat)](https://cocoapods.org/pods/ConvCache)

## Features
- [x] Asynchronous image downloading and caching.
- [x] Loading image from either URLSession-based networking or local provided data.
- [x] Multiple-layer hybrid cache for both memory and disk.
- [x] Fine control on cache behavior. Customizable expiration date and size limit.
- [x] Leverage ETags to support cache modernization
- [x] Prefetching images and showing them from the cache to boost your app.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
|iOS|Xcode|
|---|---|
|13+|13|

## Installation

### Cocoapods
```ruby
pod 'ConvCache'
```
### Usage
You can use it by entering the image URL you want to import in the example URL.
```swift
ConvCache.default.setData(URLStr: "https://example.com") { [weak self] result in
    switch result {
        case let .success(data):
            self?.imageView.image = UIImage(data: data)
        case let .failure(error):
            print(error.localizedDescription)
    }
}
```
The default capacity is set to 100 MB for memory and 50 MB for disk. If you want to change the capacity, you can set it as shown in the example below (as an integer)
```swift
ConvCache.default.configureCache(with: memoryBytes, with: diskBytes)
```

## Author
oguuk, ogw135@gmail.com

## License
ConvCache is available under the MIT license. See the LICENSE file for more info.
