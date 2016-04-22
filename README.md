# HTTPLogger
[![CI Status](http://img.shields.io/travis/muukii/HTTPLogger.svg?style=flat)](https://travis-ci.org/muukii/HTTPLogger) [![Version](https://img.shields.io/cocoapods/v/HTTPLogger.svg?style=flat)](http://cocoapods.org/pods/HTTPLogger) [![License](https://img.shields.io/cocoapods/l/HTTPLogger.svg?style=flat)](http://cocoapods.org/pods/HTTPLogger) [![Platform](https://img.shields.io/cocoapods/p/HTTPLogger.svg?style=flat)](http://cocoapods.org/pods/HTTPLogger)

## About

Logging HTTP Request of NSURLSession.


### Request Log
<img width=300 src="./Request.png">

### Response Log
<img width=300 src="./Response.png">

## Usage (Setup)

- Register NSURLProtocol

```swift
HTTPLogger.register()
```

- Setup NSURLSessionConfiguration

```swift
let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
HTTPLogger.setup(configuration)

// Sample Alamofire
Alamofire.Manager(configuration: configuration)
```

### Custom

- Create and Set Configuration

```swift
struct Configuration: HTTPLoggerConfigurationType {
  func printLog(string: String) {
    NSLog(string)
  }

  public func enableCapture(request: NSURLRequest) -> Bool {
    #if DEBUG
      return true
    #else
      return false
    #endif
  }
}
```

```swift
HTTPLogger.configuration = Configuration()
```

## Installation
HTTPLogger is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "HTTPLogger"
```

## Author
muukii, m@muukii.me

## License
HTTPLogger is available under the MIT license. See the LICENSE file for more info.
