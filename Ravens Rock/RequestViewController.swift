//
//  RequestViewController.swift
//  Ravens Rock
//
//  Created by Noirdemort on 27/12/20.
//

import Cocoa

class RequestViewController: NSViewController, NSTextFieldDelegate, NSTextViewDelegate {
    
    // MARK:- State Management
    
    var requestType: String = "GET" {
        didSet {
            requestTypeButton.selectItem(withTitle: requestType)
        }
    }
    
    var bodyFormat: String = "xo" {
        didSet {
            bodyFormatButton.selectItem(withTitle: bodyFormat)
        }
    }
    
    var headers: [String:String?] = [:] {
        willSet {
            if let expression = convertDictionaryToString(dict: newValue) {
                self.headersTextView.string = expression
            }
        }
    }
    
    var params: [String:String?] = [:] {
        willSet {
            if let expression = convertDictionaryToString(dict: newValue) {
                self.paramsTextView.string = expression
            }
        }
    }
    
    
    var request: SGRequest? = nil
    {
        didSet {
            if let solidRequest = request {
                urlTextField.stringValue = solidRequest.url
                requestType = solidRequest.httpMethod
                headers = solidRequest.headers
                params = solidRequest.params ?? [:]
                bodyTextView.string = solidRequest.body
                
                if let representation = representedObject as? SGRequestDocument {
                    representation.document = request
                    representation.objectDidEndEditing(self)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        headersTextView.font = .systemFont(ofSize: 17)
        paramsTextView.font = .systemFont(ofSize: 17)
        bodyTextView.font = .systemFont(ofSize: 17)
        headersTextView.isAutomaticQuoteSubstitutionEnabled = false
        paramsTextView.isAutomaticQuoteSubstitutionEnabled = false
        bodyTextView.isAutomaticQuoteSubstitutionEnabled = false
        
        headersTextView.delegate = self
        paramsTextView.delegate = self
        bodyTextView.delegate = self
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            for child in children {
                child.representedObject = representedObject
            }
            if let representedRequest = representedObject as? SGRequestDocument {
                request = representedRequest.document
            } else {
                print(representedObject.debugDescription)
            }
        }
    }
    
    weak var document: SGRequestDocument? {
        if let docRepresentedObject = representedObject as? SGRequestDocument {
            return docRepresentedObject
        }
        return nil
    }
    
    // MARK:- UI Layout Objects
    
    @IBOutlet weak var urlTextField: NSTextField!
    
    @IBOutlet weak var requestTypeButton: NSPopUpButton!
    
    @IBOutlet weak var headersTextView: NSTextView!
    
    @IBOutlet weak var paramsTextView: NSTextView!
    
    @IBOutlet weak var bodyFormatButton: NSPopUpButton!
    
    @IBOutlet weak var bodyTextView: NSTextView!
    
    @IBOutlet weak var responseTextView: NSTextView!
    
    @IBOutlet weak var statusCodeLabel: NSTextField!
    
    
    @IBAction func requestSelectionTapped(_ sender: Any) {
        document?.objectDidBeginEditing(self)
        if let requestType = requestTypeButton.selectedItem?.title {
            self.requestType = requestType
            document?.objectDidEndEditing(self)
        }
    }
    
    
    @IBAction func bodyFormatTapped(_ sender: NSPopUpButton) {
        print(sender.selectedItem?.title as Any)
        if let bodyFormat = sender.selectedItem?.title {
            self.bodyFormat = bodyFormat
            document?.objectDidEndEditing(self)
        }
    }
        
    @IBAction func sendRequestTapped(_ sender: Any) {
        
        if !headersTextView.string.isEmpty {
            guard let newHeaders = convertToDictionary(text: headersTextView.string) else {
                showAlert(with: "Headers Invalid JSON object. Use String:String key value pairs only.")
                return
            }
            headers = newHeaders
        }
        
        if bodyFormat != "xo" {
            headers["Content-Type"] = bodyFormat
        }
        
        if !paramsTextView.string.isEmpty {
            guard let newParams = convertToDictionary(text: paramsTextView.string) else {
                showAlert(with: "Parameters Invalid JSON object. Use String:String key value pairs only.")
                return
            }
            params = newParams
        }
        
        
        request = SGRequest(url: urlTextField.stringValue,
                  httpMethod: requestType,
                  params: params,
                  headers: headers,
                  body: requestType != "GET" ? bodyTextView.string : .init())
        
        
        request?.makeRequest(){[weak self] (response, statusCode) in
                    
                DispatchQueue.main.async {
                    self?.responseTextView.string = response ?? "No response received."
                    self?.statusCodeLabel.stringValue = "\(statusCode ?? -100)"
                }
        }
    }
    
    func showAlert(with text: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Error Occured!!"
        alert.informativeText = text
        alert.runModal()
    }
    
    
    func textDidBeginEditing(_ notification: Notification) {
        document?.objectDidBeginEditing(self)
    }
    
    func textDidEndEditing(_ notification: Notification) {
        
        document?.objectDidEndEditing(self)
//        guard let identifier = (notification.object as? NSTextView)?.identifier?.rawValue else { return }
//
//
//        switch identifier {
//
//        case "bodyTextView":
//            request?.body = bodyTextView.string
//
//        case "headersTextView":
//            if let data = convertToDictionary(text: headersTextView.string)  {
//                request?.headers = data
//                print(data)
//            }
//
//        case "paramsTextView":
//            if let data = convertToDictionary(text: paramsTextView.string)  {
//                request?.params = data
//            }
//
//
//        default:
//            return
//        }
    }
    
    func refreshDocument() {
        request = SGRequest(url: urlTextField.stringValue,
                         httpMethod: requestType,
                         params: params,
                         headers: headers, body: bodyTextView.string)
    }
    
}

func convertToDictionary(text: String) -> [String: String?]? {
    guard let data = text.data(using: .utf8, allowLossyConversion: false) else { return nil }
    do {
        let object = try JSONSerialization.jsonObject(with: data, options: .init())
        
        if let cast = object as? [String:String?] {
            return cast
        }
        
    } catch {
        print(error.localizedDescription)
    }
    
    return nil
}


func convertDictionaryToString(dict: [String:String?]) -> String? {
    do {
        let object = try JSONSerialization.data(withJSONObject: dict, options: .withoutEscapingSlashes)
        return String(data: object, encoding: .utf8)
    } catch {
        print(error.localizedDescription)
    }
    return nil
}
