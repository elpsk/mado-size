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
            print("Failed to get the application that currently has focus.")
            return nil
        }
        
        let appElement = AXUIElementCreateApplication(frontmostApplication.processIdentifier).takeRetainedValue()

        var result: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute, &result) == .Success else {
            print("Failed to get the window that currently has focus.")
            return nil
        }
        
        let windowElement = result as! AXUIElementRef
        return AppWindow(app: frontmostApplication, appElement: appElement, windowElement: windowElement)
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
    
    func center() {
        if let screen = screen(), size = size {
            let newX = screen.visibleFrame.midX - size.width / 2
            let newY = screen.frame.maxY - (screen.visibleFrame.midY + size.height / 2)
            position = CGPoint(x: newX, y: newY)
        }
    }
    
    func maximize() {
        if let screen = screen() {
            position = CGPoint(x: screen.visibleFrame.minX, y: screen.frame.maxY - screen.visibleFrame.maxY)
            size = screen.visibleFrame.size
        }
    }
    
    func activateWithOptions(options: NSApplicationActivationOptions) {
        app.activateWithOptions(options)
    }
    
    func screen() -> NSScreen? {
        guard let screens = NSScreen.screens(), position = position, size = size else {
            return nil
        }
        
        let appFrame = NSRect(origin: position, size: size)
        
        var result: NSScreen? = nil
        var area: CGFloat = 0

        for screen in screens {
            let overlap = screen.frame.intersect(appFrame)
            if overlap.width * overlap.height > area {
                area = overlap.width * overlap.height
                result = screen
            }
        }
        
        return result
    }
    
    var position: CGPoint? {
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