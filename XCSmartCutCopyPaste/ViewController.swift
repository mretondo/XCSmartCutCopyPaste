//
//  ViewController.swift
//  XCSmartCutCopyPaste
//
//  Created by Mike Retondo on 8/26/18.
//  Copyright © 2018 Mike Retondo. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBAction func actionOpenGithub(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/mretondo/XCSmartCutCopyPaste")!)
    }
}

