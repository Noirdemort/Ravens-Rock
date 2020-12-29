//
//  SGRequestDocument.swift
//  Ravens Rock
//
//  Created by Noirdemort on 27/12/20.
//

import Cocoa

class SGRequest: NSObject, Codable {
   
    internal init(url: String, httpMethod: String, params: [String : String?], headers: [String : String?], body: String) {
        self.url = url
        self.httpMethod = httpMethod
        self.params = params
        self.headers = headers
        self.body = body
    }
    
    
    var url: String
    var httpMethod: String
    var params: [String: String?]?
    var headers: [String: String?]
    var body: String {
        didSet {
            body = body.replacingOccurrences(of: "\\", with: "")
        }
    }
    
    
    func makeRequest(completionHandler: @escaping (String?, Int?) -> Void ) {
        
        guard var urlComponents = URLComponents(string: url) else {
            completionHandler("Can't get url components", nil)
            return
        }
            
        for param in params ?? [:] {
            urlComponents.queryItems?.append(URLQueryItem(name: param.key, value: param.value))
        }
        
        guard let url = urlComponents.url else {
            completionHandler("Failed to extract URL, Check for invalid url!!", nil)
            return
            
        }
        
        var urlRequest = URLRequest(url: url)
        
        urlRequest.allowsCellularAccess = true
        urlRequest.httpMethod = httpMethod
        for header in headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        urlRequest.httpBody = body.data(using: .utf8)
        
        let session = URLSession.shared
        
        session.dataTask(with: urlRequest){ (data, response, error) in
            
            var statusCode: Int? = nil
            
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            
            if error != nil {
                completionHandler(error?.localizedDescription, statusCode)
            }
            
            if let receivedData = data, let decodedString = String(data: receivedData, encoding: .utf8) {
                completionHandler(decodedString, statusCode)
            }
            
        }.resume()
        
    }
    
}


class SGRequestDocument: NSDocument {

    var document: SGRequest? = nil
    weak var contentViewController: RequestViewController!

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }
    
    override class var autosavesDrafts: Bool  {
        return true
    }
    
    
//    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
//        return true
//    }
    
    override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
        return typeName == "public.json"
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
//        windowController.contentViewController?.representedObject = self
        self.addWindowController(windowController)
        if let contentVC = windowController.contentViewController as? RequestViewController {
            contentVC.representedObject = self
            contentViewController = contentVC
        }
    }

//    override func write(to url: URL, ofType typeName: String) throws {
//        let encoder = JSONEncoder()
//        encoder.dataEncodingStrategy = .deferredToData
//        encoder.keyEncodingStrategy = .convertToSnakeCase
//        encoder.outputFormatting = .withoutEscapingSlashes
//        let data = try encoder.encode(document)
//        try? data.write(to: url, options: .atomicWrite)
//        Swift.print("called me")
//    }
    
    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .deferredToData
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .withoutEscapingSlashes
        Swift.print("Was this called")
        contentViewController.refreshDocument()
        let data = try encoder.encode(document)
        return data
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.
        // If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
//        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .deferredToData
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        document = try decoder.decode(SGRequest.self, from: data)
    }


}

