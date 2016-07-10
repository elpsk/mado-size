//
//  DimensionsViewController.swift
//  MadoSize
//
//  Created by Shad Sharma on 7/9/16.
//  Copyright © 2016 Shad Sharma. All rights reserved.
//

import Cocoa

class DimensionsViewController: NSViewController {
    @IBOutlet weak var xPosTextField: NSTextField!
    @IBOutlet weak var yPosTextField: NSTextField!
    @IBOutlet weak var widthTextField: NSTextField!
    @IBOutlet weak var heightTextField: NSTextField!
    @IBOutlet weak var centerButton: NSButton!
    @IBOutlet weak var titleLabel: NSTextField!

    @IBOutlet weak var settingsButton: NSButton!
    @IBOutlet weak var settingsMenu: NSMenu!
    
    var window: AppWindow?
    var monitor: AnyObject?

    convenience init(window: AppWindow?) {
        self.init(nibName: "DimensionsViewController", bundle: nil)!
        self.window = window
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        load()
        
        NSApp.activateIgnoringOtherApps(true)
        monitor = NSEvent.addGlobalMonitorForEventsMatchingMask([.LeftMouseDownMask, .RightMouseDownMask],
                                                                handler: self.cancelOperation)
    }
    
    override func viewWillDisappear() {
        if let window = window {
            window.activateWithOptions(.ActivateAllWindows)
        }
    }
    
    func enableControls(enabled: Bool) {
        xPosTextField.enabled = enabled
        yPosTextField.enabled = enabled
        widthTextField.enabled = enabled
        heightTextField.enabled = enabled
        centerButton.enabled = enabled
    }
    
    func load() {
        if let window = window, title = window.appTitle, position = window.position, size = window.size {
            enableControls(true)
            titleLabel.stringValue = "Mado: \(title)"
            xPosTextField.integerValue = Int(position.x)
            yPosTextField.integerValue = Int(position.y)
            widthTextField.integerValue = Int(size.width)
            heightTextField.integerValue = Int(size.height)
        } else {
            titleLabel.stringValue = "Mado: Nothing Selected"
            enableControls(false)
        }
    }
    
    override func cancelOperation(sender: AnyObject?) {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
 
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.closeDimensionsView(self)
        }
    }

    @IBAction func quitApplication(sender: AnyObject) {
        NSApp.terminate(self)
    }

    @IBAction func showSettingsMenu(sender: AnyObject) {
        NSMenu.popUpContextMenu(settingsMenu, withEvent: NSApp.currentEvent!, forView: settingsButton)
    }
    
    @IBAction func positionFieldChanged(sender: NSTextField) {
        guard let window = window else {
            return
        }

        window.position = CGPoint(x: xPosTextField.integerValue, y: yPosTextField.integerValue)
        load()
    }
    
    @IBAction func sizeFieldChanged(sender: NSTextField) {
        guard let window = window else {
            return
        }
        
        window.size = CGSize(width: widthTextField.integerValue, height: heightTextField.integerValue)
        load()
    }

    @IBAction func centerWindow(sender: AnyObject) {
        guard let window = window else {
            return
        }
        
        window.center()
        load()
    }
}
