//
//  BridgePlatform.swift
//  THGBridge
//
//  Created by Angelo Di Paolo on 4/22/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import JavaScriptCore

private let bridgePlatformExportName = "NativeBridge"

@objc protocol PlatformJSExport: JSExport {
    var navigation: BridgeNavigation {get}
    func updatePageState(options: [String: AnyObject])
    func log(value: AnyObject)
}

@objc protocol ShareJSExport: JSExport {
    func share(options: [String: AnyObject])
}

@objc class BridgePlatform: WebViewControllerScript, PlatformJSExport {
    var navigation = BridgeNavigation()
    lazy var dialogDelegate: BridgeDialog = { return BridgeDialog() }()
    
    override weak var parentWebViewController: WebViewController? {
        didSet {
            navigation.parentWebViewController = parentWebViewController
        }
    }
    
    func updatePageState(options: [String: AnyObject]) {
        
        if let title = options["title"] as? String {
            parentWebViewController?.title = title
        }
    }
    
    func log(value: AnyObject) {
        println("BridgeOfDeath: \(value)")
    }
}

// MARK: - ShareJSExport

extension BridgePlatform: ShareJSExport {
    
    func share(options: [String: AnyObject]) {
        if let items = shareItemsFromOptions(options) {
            dispatch_async(dispatch_get_main_queue()) {
                var activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
                self.parentWebViewController?.presentViewController(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    private func shareItemsFromOptions(options: [String: AnyObject]) -> [AnyObject]? {
        if let message = options["message"] as? String,
            let url = options["url"] as? String {
            return [url, message]
        }
        
        return nil
    }
}

// MARK: - DialogJSExport

extension BridgePlatform: DialogJSExport {
    
    func dialog(options: [String: AnyObject], _ callback: JSValue) {
        dispatch_async(dispatch_get_main_queue()) {
            self.dialogDelegate.showWithOptions(options, callback: callback)
        }
    }
}

// MARK: - WebViewController Integration

public extension WebViewController {
    
    static func WithBridgePlatform() -> WebViewController {
        let webViewController = WebViewController()
        webViewController.bridge.addExport(BridgePlatform(), name: bridgePlatformExportName)
        return webViewController
    }
}

// MARK: - Bridge Integration

extension Bridge {
    
    var platform: BridgePlatform? {
        return contextValueForName(bridgePlatformExportName).toObject() as? BridgePlatform
    }
}