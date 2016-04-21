// HTTPLogger
//
// Copyright (c) 2015 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

public final class HTTPLogger: NSURLProtocol {
    
    // MARK: - Public
    
    public static var printTarget: (String -> Void) = { print($0) }
    
    public class func register() {
        NSURLProtocol.registerClass(self)
    }
    
    public class func unregister() {
        NSURLProtocol.unregisterClass(self)
    }
    
    public class func setup(configuration: NSURLSessionConfiguration) {        
        configuration.protocolClasses?.insert(HTTPLogger.self, atIndex: 0)
    }
    
    //MARK: - NSURLProtocol
    
    public override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard self.propertyForKey(requestHandledKey, inRequest: request) == nil else {
            return false
        }
        
        return true
    }
    
    public override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    public override class func requestIsCacheEquivalent(a: NSURLRequest, toRequest b: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, toRequest: b)
    }
    
    public override func startLoading() {
        guard let req = request.mutableCopy() as? NSMutableURLRequest where newRequest == nil else { return }
        
        self.newRequest = req
        
        HTTPLogger.setProperty(true, forKey: HTTPLogger.requestHandledKey, inRequest: newRequest!)
        HTTPLogger.setProperty(NSDate(), forKey: HTTPLogger.requestTimeKey, inRequest: newRequest!)
        
        connection = NSURLConnection(request: newRequest!, delegate: self)
        
        logRequest(newRequest!)
    }
    
    public override func stopLoading() {
        connection?.cancel()
        connection = nil
    }
    
    // MARK: NSURLConnectionDelegate
    
    func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        let policy = NSURLCacheStoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .NotAllowed
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: policy)
        
        self.response = response
        self.data = NSMutableData()
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        client?.URLProtocol(self, didLoadData: data)
        self.data?.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        client?.URLProtocolDidFinishLoading(self)
        
        if let response = response {
            logResponse(response, data: data)
        }
    }
    
    func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        client?.URLProtocol(self, didFailWithError: error)
        logError(error)
    }
    
    //MARK: - Logging
    
    public func logError(error: NSError) {
        
        var logString = "⚠️\n"
        logString += "Error: \n\(error.localizedDescription)\n"
        
        if let reason = error.localizedFailureReason {
            logString += "Reason: \(reason)\n"
        }
        
        if let suggestion = error.localizedRecoverySuggestion {
            logString += "Suggestion: \(suggestion)\n"
        }
        logString += "\n\n*************************\n\n"
        HTTPLogger.printTarget(logString)
    }
    
    public func logRequest(request: NSURLRequest) {
        var logString = "\n📤"
        if let url = request.URL?.absoluteString {
            logString += "Request: \n  \(request.HTTPMethod!) \(url)\n"
        }
        
        if let headers = request.allHTTPHeaderFields {
            logString += "Header:\n"
            logString += logHeaders(headers) + "\n"
        }

        if let data = request.HTTPBody,
            let bodyString = NSString(data: data, encoding: NSUTF8StringEncoding) {
            
            logString += "Body:\n"
            logString += bodyString as String
        }
        
        if let dataStream = request.HTTPBodyStream {
            
            let bufferSize = 1024
            var buffer = [UInt8](count: bufferSize, repeatedValue: 0)
            
            let data = NSMutableData()
            dataStream.open()
            while dataStream.hasBytesAvailable {
                let bytesRead = dataStream.read(&buffer, maxLength: bufferSize)
                data.appendBytes(buffer, length: bytesRead)
            }
            
            if let bodyString = NSString(data: data, encoding: NSUTF8StringEncoding) {
                logString += "Body:\n"
                logString += bodyString as String
            }
        }
        
        logString += "\n\n*************************\n\n"
        HTTPLogger.printTarget(logString)
    }
    
    public func logResponse(response: NSURLResponse, data: NSData? = nil) {
        
        var logString = "\n📥"
        if let url = response.URL?.absoluteString {
            logString += "Response: \n  \(url)\n"
        }
        
        if let httpResponse = response as? NSHTTPURLResponse {
            let localisedStatus = NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode).capitalizedString
            logString += "Status: \n  \(httpResponse.statusCode) - \(localisedStatus)\n"
        }
        
        if let headers = (response as? NSHTTPURLResponse)?.allHeaderFields as? [String: AnyObject] {
            logString += "Header: \n"
            logString += self.logHeaders(headers) + "\n"
        }
        
        if let startDate = HTTPLogger.propertyForKey(HTTPLogger.requestTimeKey, inRequest: newRequest!) as? NSDate {
            let difference = fabs(startDate.timeIntervalSinceNow)
            logString += "Duration: \n  \(difference)s\n"
        }
        
        guard let data = data else { return }
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
            let pretty = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
            
            if let string = NSString(data: pretty, encoding: NSUTF8StringEncoding) {
                logString += "\nJSON: \n\(string)"
            }
        }
        catch {
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                logString += "\nData: \n\(string)"
            }
        }
        
        logString += "\n\n*************************\n\n"
        HTTPLogger.printTarget(logString)
    }
    
    public func logHeaders(headers: [String: AnyObject]) -> String {
        
        let string = headers.reduce(String()) { str, header in
            let string = "  \(header.0) : \(header.1)"
            return str + "\n" + string
        }
        let logString = "[\(string)\n]"
        return logString
    }
    
    // MARK: - Private
    
    private static let requestHandledKey = "RequestLumberjackHandleKey"
    private static let requestTimeKey = "RequestLumberjackRequestTime"
    
    private var connection: NSURLConnection?
    private var data: NSMutableData?
    private var response: NSURLResponse?
    private var newRequest: NSMutableURLRequest?
}
