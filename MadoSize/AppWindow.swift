//
//  AccessibilityElement.swift
//  MadoSize
//
//  Created by Shad Sharma on 7/3/16.
//  Copyright © 2016 Shad Sharma. All rights reserved.
//

import Cocoa
import Foundation

class AppWindow {
    let app: NSRunningApplication
    let appElement: AXUIElementRef
    let windowElement: AXUIElementRef
    
    static func frontmost() -> AppWindow? {
        guard let frontmostApplication = NSWorkspace.sharedWorkspace().frontmostApplication else {
            return nil
        }
        
        let appElement = AXUIElementCreateApplication(frontmostApplication.processIdentifier).takeRetainedValue()

        var result: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute, &result) == .Success else {
            return nil
        }
        
        let windowElement = result as! AXUIElementRef
        return AppWindow(app: frontmostApplication, appElement: appElement, windowElement: windowElement)
    }
    
    var primaryScreenHeight: CGFloat {
        get {
            if let screens = NSScreen.screens() {
                return screens[0].frame.maxY
            } else {
                return 0
            }
        }
    }
    
    init(app: NSRunningApplication, appElement: AXUIElementRef, windowElement: AXUIElementRef) {
        self.app = app
        self.appElement = appElement
        self.windowElement = windowElement
    }
    
    private func value(attribute: String, type: AXValueType) -> AXValueRef? {
        guard CFGetTypeID(windowElement) == AXUIElementGetTypeID() else {
            return nil
        }
        
        var result: AnyObject?
        guard AXUIElementCopyAttributeValue(windowElement, attribute, &result) == .Success else {
            return nil
        }
        
        let value = result as! AXValueRef
        guard AXValueGetType(value) == type else {
            return nil
        }
        
        return value
    }
    
    private func setValue(value: AXValueRef, attribute: String) {
        let status = AXUIElementSetAttributeValue(windowElement, attribute, value)

        if status != .Success {
            print("Failed to set \(attribute)=\(value)")
        }
    }
    
    private var appOrigin: CGPoint? {
        get {
            guard let positionValue = value(kAXPositionAttribute, type: .CGPoint) else {
                return nil
            }
            
            var position = CGPoint()
            AXValueGetValue(positionValue, .CGPoint, &position)
            
            return position
        }
        
        set {
            var origin = newValue
            guard let value = AXValueCreate(.CGPoint, &origin) else {
                print("Failed to create positionRef")
                return
            }
            
            let positionRef = value.takeRetainedValue()
            setValue(positionRef, attribute: kAXPositionAttribute)
        }
    }
    
    var origin: CGPoint? {
        get {
            guard let appOrigin = appOrigin, size = size else {
                return nil
            }
            
            return CGPoint(x: appOrigin.x, y: primaryScreenHeight - size.height - appOrigin.y)
        }
        
        set {
            if let newOrigin = newValue, size = size {
                appOrigin = CGPoint(x: newOrigin.x, y: primaryScreenHeight - size.height - newOrigin.y)
            }
        }
    }
    
    var size: CGSize? {
        get {
            guard let sizeValue = value(kAXSizeAttribute, type: .CGSize) else {
                return nil
            }
            
            var size = CGSize()
            AXValueGetValue(sizeValue, .CGSize, &size)
            
            return size
        }
        
        set {
            var size = newValue
            guard let value = AXValueCreate(.CGSize, &size) else {
                print("Failed to create sizeRef")
                return
            }
            
            let sizeRef = value.takeRetainedValue()
            setValue(sizeRef, attribute: kAXSizeAttribute)
        }
    }
    
    var globalFrame: CGRect? {
        get {
            guard let origin = appOrigin, size = size else {
                return nil
            }
            
            return CGRect(origin: CGPoint(x: origin.x, y: primaryScreenHeight - size.height - origin.y), size: size)
        }
        
        set {
            if let frame = newValue {
                appOrigin = CGPoint(x: frame.origin.x, y: primaryScreenHeight - frame.size.height - frame.origin.y)
                size = frame.size
            }
        }
    }
    
    var frame: CGRect? {
        get {
            guard let screen = screen(), globalFrame = globalFrame else {
                return nil
            }
            
            return CGRect(origin: globalFrame.origin - screen.frame.origin, size: globalFrame.size)
        }
        
        set {
            if let screen = screen(), localFrame = newValue {
                globalFrame = CGRect(origin: localFrame.origin + screen.frame.origin, size: localFrame.size)
            }
        }
    }
    
    
    func center() {
        if let screen = screen(), size = size {
            let newX = screen.visibleFrame.midX - size.width / 2
            let newY = screen.visibleFrame.midY - size.height / 2
            origin = CGPoint(x: newX, y: newY)
        }
    }
    
    func maximize() {
        if let screen = screen() {
            globalFrame = screen.visibleFrame
        }
    }
    
    func activateWithOptions(options: NSApplicationActivationOptions) {
        app.activateWithOptions(options)
    }
    
    func screen() -> NSScreen? {
        guard let screens = NSScreen.screens(), screenFrame = globalFrame else {
            return nil
        }
        
        var result: NSScreen? = nil
        var area: CGFloat = 0

        print("App Frame: \(screenFrame)")
        for (index, screen) in screens.enumerate() {
            print("Screen \(index): \(screen.frame)")
            let overlap = screen.frame.intersect(screenFrame)
            if overlap.width * overlap.height > area {
                area = overlap.width * overlap.height
                result = screen
            }
        }
        
        return result
    }
    
    var appTitle: String? {
        get {
            guard CFGetTypeID(appElement) == AXUIElementGetTypeID() else {
                return nil
            }
            
            var result: AnyObject?
            guard AXUIElementCopyAttributeValue(appElement, kAXTitleAttribute, &result) == .Success else {
                return nil
            }
            
            return result as? String
        }
    }
    
    var windowTitle: String? {
        get {
            guard CFGetTypeID(windowElement) == AXUIElementGetTypeID() else {
                return nil
            }
            
            var result: AnyObject?
            guard AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute, &result) == .Success else {
                return nil
            }
            
            return result as? String
        }
    }
}

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}