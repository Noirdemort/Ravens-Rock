//
//  AppDelegate.swift
//  Ravens Rock
//
//  Created by Noirdemort on 27/12/20.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    @IBAction func exportResponse(_ sender: Any) {
        if let rVC = NSApp.mainWindow?.contentViewController as? RequestViewController {
            print(rVC.responseTextView.string)
        }
    }
    
    

}

