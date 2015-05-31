//
//  SelfIntersectionView.swift
//  SelfIntersectionViewer
//
//  Created by Litherum on 5/30/15.
//  Copyright (c) 2015 Litherum. All rights reserved.
//

import Cocoa

class SelfIntersectionView : NSView {
    var p0: CGPoint
    var p1: CGPoint
    var p2: CGPoint
    var p3: CGPoint
    let pointRadius = CGFloat(10)

    enum DraggedPoint {
        case Point0
        case Point1
        case Point2
        case Point3
    }
    var draggedPoint: DraggedPoint?

    var intersectionPoint: NSPoint?

    required init?(coder: NSCoder) {
        p0 = CGPointMake(100, 100)
        p1 = CGPointMake(450, 200)
        p2 = CGPointMake(50, 200)
        p3 = CGPointMake(400, 100)
        super.init(coder: coder)
        updateIntersectionPoint()
    }

    func drawControlPoint(point: CGPoint) {
        NSBezierPath(ovalInRect: NSMakeRect(point.x - pointRadius, point.y - pointRadius, pointRadius * 2, pointRadius * 2)).stroke()
    }

    override func drawRect(dirtyRect: NSRect) {
        var path = NSBezierPath()
        path.moveToPoint(p0)
        path.curveToPoint(p3, controlPoint1: p1, controlPoint2: p2)
        path.stroke()
        
        drawControlPoint(p0)
        drawControlPoint(p1)
        drawControlPoint(p2)
        drawControlPoint(p3)

        if let intersectionPoint = intersectionPoint {
            NSColor.redColor().set()
            drawControlPoint(intersectionPoint)
        }
    }

    func mouseIsOver(mouseLocation: NSPoint, point: NSPoint) -> Bool {
        let dx = mouseLocation.x - point.x
        let dy = mouseLocation.y - point.y
        return sqrt(dx * dx + dy * dy) < pointRadius
    }

    override func mouseDown(theEvent: NSEvent) {
        let mouseLocation = convertPoint(theEvent.locationInWindow, fromView: nil)
        if mouseIsOver(mouseLocation, point: p0) {
            draggedPoint = .Point0
        } else if mouseIsOver(mouseLocation, point: p1) {
            draggedPoint = .Point1
        } else if mouseIsOver(mouseLocation, point: p2) {
            draggedPoint = .Point2
        } else if mouseIsOver(mouseLocation, point: p3) {
            draggedPoint = .Point3
        }
    }

    override func mouseUp(theEvent: NSEvent) {
        draggedPoint = nil
    }

    override func mouseDragged(theEvent: NSEvent) {
        if let draggedPoint = draggedPoint {
            let mouseDelta = NSMakeSize(theEvent.deltaX, theEvent.deltaY)
            switch draggedPoint {
            case .Point0:
                p0 = NSMakePoint(p0.x + mouseDelta.width, p0.y - mouseDelta.height)
            case .Point1:
                p1 = NSMakePoint(p1.x + mouseDelta.width, p1.y - mouseDelta.height)
            case .Point2:
                p2 = NSMakePoint(p2.x + mouseDelta.width, p2.y - mouseDelta.height)
            case .Point3:
                p3 = NSMakePoint(p3.x + mouseDelta.width, p3.y - mouseDelta.height)
            }
            updateIntersectionPoint()
            setNeedsDisplayInRect(self.bounds)
        }
    }

    func updateIntersectionPoint() {
        let a = 3 * (p1.x - p0.x)
        let b = 3 * (p0.x - 2 * p1.x + p2.x)
        let c = 3 * p1.x - p0.x - 3 * p2.x + p3.x
        let p = 3 * (p1.y - p0.y)
        let q = 3 * (p0.y - 2 * p1.y + p2.y)
        let r = 3 * p1.y - p0.y - 3 * p2.y + p3.y
        let cqbr = c * q - b * r
        let discriminant = -cqbr * cqbr * (3 * a * a * r * r - 4 * a * b * q * r - 6 * a * c * p * r + 4 * a * c * q * q + 4 * b * b * p * r - 4 * b * c * p * q + 3 * c * c * p * p)
        if discriminant <= 0 {
            intersectionPoint = nil
            return
        }
        let rest = -a * b * r * r + a * c * q * r + b * c * p * r + c * c * (-p) * q
        let s = 1 / (2 * cqbr * cqbr) * (-sqrt(discriminant) + rest)
        let t = 1 / (2 * cqbr * cqbr) * (sqrt(discriminant) + rest)
        if s < 0 || s >= 1 || t < 0 || t >= 1 {
            intersectionPoint = nil
            return
        }
        let small = 1 - s
        let b0 = small * small * small
        let b1 = 3 * s * small * small
        let b2 = 3 * s * s * small
        let b3 = s * s * s
        intersectionPoint = NSMakePoint(b0 * p0.x + b1 * p1.x + b2 * p2.x + b3 * p3.x, b0 * p0.y + b1 * p1.y + b2 * p2.y + b3 * p3.y)
    }
}
