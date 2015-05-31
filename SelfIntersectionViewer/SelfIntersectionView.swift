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
    var q0: CGPoint
    var q1: CGPoint
    var q2: CGPoint
    var q3: CGPoint
    let pointRadius = CGFloat(10)
    var lminsaved: (CGFloat, CGFloat, CGFloat)
    var lmaxsaved: (CGFloat, CGFloat, CGFloat)
    var clippedBezier: (CGPoint, CGPoint, CGPoint, CGPoint)

    enum ParticularPoint {
        case Point0
        case Point1
        case Point2
        case Point3
    }
    var draggedPoint: ParticularPoint?

    var intersectionPoint: NSPoint?

    required init?(coder: NSCoder) {
        p0 = CGPointMake(100, 100)
        p1 = CGPointMake(450, 200)
        p2 = CGPointMake(50, 200)
        p3 = CGPointMake(400, 100)
        q0 = CGPointMake(100, 200)
        q1 = CGPointMake(450, 300)
        q2 = CGPointMake(50, 300)
        q3 = CGPointMake(400, 200)
        lminsaved = (0, 0, 0)
        lmaxsaved = (0, 0, 0)
        clippedBezier = (CGPointZero, CGPointZero, CGPointZero, CGPointZero)
        super.init(coder: coder)
        updateIntersectionPoint()
        if let clipped = clipping(p0: p0, p1: p1, p2: p2, p3: p3, q0: q0, q1: q1, q2: q2, q3: q3) {
            clippedBezier = clipped
        } else {
            clippedBezier = (NSZeroPoint, NSZeroPoint, NSZeroPoint, NSZeroPoint)
        }
    }

    func drawControlPoint(point: CGPoint) {
        NSBezierPath(ovalInRect: NSMakeRect(point.x - pointRadius, point.y - pointRadius, pointRadius * 2, pointRadius * 2)).stroke()
    }

    func drawLine(abc: (CGFloat, CGFloat, CGFloat)) {
        let path = NSBezierPath()
        if abc.0 == 0 && abc.1 == 0 {
            return
        }
        if abs(abc.1) < abs(abc.0) {
            let y = self.bounds.height
            path.moveToPoint(NSMakePoint(-abc.2 / abc.0, 0))
            path.lineToPoint(NSMakePoint((-abc.1 * y - abc.2) / abc.0, y))
        } else {
            let x = self.bounds.width
            path.moveToPoint(NSMakePoint(0, -abc.2 / abc.1))
            path.lineToPoint(NSMakePoint(x, (-abc.0 * x - abc.2) / abc.1))
        }
        path.stroke()
    }

    override func drawRect(dirtyRect: NSRect) {
        var path = NSBezierPath()
        path.moveToPoint(p0)
        path.curveToPoint(p3, controlPoint1: p1, controlPoint2: p2)
        path.stroke()

        path = NSBezierPath()
        path.moveToPoint(q0)
        path.curveToPoint(q3, controlPoint1: q1, controlPoint2: q2)
        path.stroke()
        
        drawControlPoint(p0)
        drawControlPoint(p1)
        drawControlPoint(p2)
        drawControlPoint(p3)

        if let intersectionPoint = intersectionPoint {
            NSColor.redColor().set()
            drawControlPoint(intersectionPoint)
        }

        NSColor.blueColor().set()
        drawLine(lminsaved)
        drawLine(lmaxsaved)

        NSColor.purpleColor().set()
        path = NSBezierPath()
        path.moveToPoint(clippedBezier.0)
        path.curveToPoint(clippedBezier.3, controlPoint1: clippedBezier.1, controlPoint2: clippedBezier.2)
        path.stroke()
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
            if let clipped = clipping(p0: p0, p1: p1, p2: p2, p3: p3, q0: q0, q1: q1, q2: q2, q3: q3) {
                clippedBezier = clipped
            } else {
                clippedBezier = (NSZeroPoint, NSZeroPoint, NSZeroPoint, NSZeroPoint)
            }
            setNeedsDisplayInRect(self.bounds)
        }
    }

    func interpolatePoint(t: CGFloat, point0: CGPoint, point1: CGPoint, point2: CGPoint, point3: CGPoint) -> CGPoint {
        let small = 1 - t
        let b0 = small * small * small
        let b1 = 3 * t * small * small
        let b2 = 3 * t * t * small
        let b3 = t * t * t
        return NSMakePoint(b0 * point0.x + b1 * point1.x + b2 * point2.x + b3 * point3.x, b0 * point0.y + b1 * point1.y + b2 * point2.y + b3 * point3.y)
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
        intersectionPoint = interpolatePoint(s, point0: p0, point1: p1, point2: p2, point3: p3)
    }

    func distance(a: CGFloat, b: CGFloat, c: CGFloat, point: CGPoint) -> CGFloat {
        return a * point.x + b * point.y + c
    }

    func cross(u1: CGFloat, u2: CGFloat, u3: CGFloat, v1: CGFloat, v2: CGFloat, v3: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        return (u2 * v3 - u3 * v2, u3 * v1 - u1 * v3, u1 * v2 - u2 * v1)
    }

    func dot(u1: CGFloat, u2: CGFloat, u3: CGFloat, v1: CGFloat, v2: CGFloat, v3: CGFloat) -> CGFloat {
        return u1 * v1 + u2 * v2 + u3 * v3
    }

    func lerp(point0: CGPoint, point1: CGPoint, t: CGFloat) -> CGPoint {
        return CGPointMake(point1.x * t + point0.x * (1 - t), point1.y * t + point0.y * (1 - t))
    }

    func clipOnce(e0: CGFloat, e1: CGFloat, e2: CGFloat, e3: CGFloat) -> CGFloat? {
        if e0 > 0 || e3 < 0 {
            return nil
        }
        var result: CGFloat?
        let l01 = cross(0, u2: e0, u3: 1, v1: CGFloat(1) / 3, v2: e1, v3: 1)
        let l02 = cross(0, u2: e0, u3: 1, v1: CGFloat(2) / 3, v2: e2, v3: 1)
        let l03 = cross(0, u2: e0, u3: 1, v1: 1, v2: e3, v3: 1)
        let v1 = cross(l01.0, u2: l01.1, u3: l01.2, v1: 0, v2: 1, v3: 0)
        let v2 = cross(l02.0, u2: l02.1, u3: l02.2, v1: 0, v2: 1, v3: 0)
        let v3 = cross(l03.0, u2: l03.1, u3: l03.2, v1: 0, v2: 1, v3: 0)
        let v1c = (v1.0 / v1.2, v1.1 / v1.2)
        let v2c = (v2.0 / v2.2, v2.1 / v2.2)
        let v3c = (v3.0 / v3.2, v3.1 / v3.2)
        if v1c.0 > 0 {
            result = v1c.0
        }
        if v2c.0 > 0 && (result == nil || v2c.0 < result!) {
            result = v2c.0
        }
        if v3c.0 > 0 && (result == nil || v3c.0 < result!) {
            result = v3c.0
        }
        return result
    }

    func clipping(p0 p0in: CGPoint, p1 p1in: CGPoint, p2 p2in: CGPoint, p3 p3in: CGPoint, q0: CGPoint, q1: CGPoint, q2: CGPoint, q3: CGPoint) -> (CGPoint, CGPoint, CGPoint, CGPoint)? {
        // Bezier Clipping. http://cagd.cs.byu.edu/~557/text/ch7.pdf
        let (l0, l1, l2) = cross(q0.x, u2: q0.y, u3: 1, v1: q3.x, v2: q3.y, v3: 1)
        let c1 = -l0 * q1.x - l1 * q1.y
        let c2 = -l0 * q2.x - l1 * q2.y
        var lmin = (-l0, -l1, -min(min(l2, c1), c2))
        var lmax = (l0, l1, max(max(l2, c1), c2))
        lminsaved = lmin
        lmaxsaved = lmax
        
        var point0 = p0in
        var point1 = p1in
        var point2 = p2in
        var point3 = p3in

        var e0min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point0.x, v2: point0.y, v3: 1)
        var e1min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point1.x, v2: point1.y, v3: 1)
        var e2min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point2.x, v2: point2.y, v3: 1)
        var e3min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point3.x, v2: point3.y, v3: 1)
        var e0max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point0.x, v2: point0.y, v3: 1)
        var e1max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point1.x, v2: point1.y, v3: 1)
        var e2max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point2.x, v2: point2.y, v3: 1)
        var e3max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point3.x, v2: point3.y, v3: 1)

        if ((e0min < 0 && e1min < 0 && e2min < 0 && e3min < 0) || (e0max < 1 && e1max < 1 && e2max < 1 && e3max < 1)) {
            return nil
        }

        var minT: CGFloat? = nil
        if let clipped = clipOnce(e0min, e1: e1min, e2: e2min, e3: e3min) {
            minT = clipped
        }
        if let clipped = clipOnce(e0max, e1: e1max, e2: e2max, e3: e3max) {
            if let t = minT {
                minT = min(t, clipped)
            } else {
                minT = clipped
            }
        }
        
        var clipMinT: CGFloat
        if let minT = minT {
            clipMinT = minT
        } else {
            clipMinT = 0
        }

        var p01 = lerp(point0, point1: point1, t: clipMinT)
        var p12 = lerp(point1, point1: point2, t: clipMinT)
        var p23 = lerp(point2, point1: point3, t: clipMinT)
        var p012 = lerp(p01, point1: p12, t: clipMinT)
        var p123 = lerp(p12, point1: p23, t: clipMinT)
        var p0123 = lerp(p012, point1: p123, t: clipMinT)
        (point0, point1, point2, point3) = (p0123, p123, p23, point3)




        e0min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point0.x, v2: point0.y, v3: 1)
        e1min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point1.x, v2: point1.y, v3: 1)
        e2min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point2.x, v2: point2.y, v3: 1)
        e3min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point3.x, v2: point3.y, v3: 1)
        e0max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point0.x, v2: point0.y, v3: 1)
        e1max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point1.x, v2: point1.y, v3: 1)
        e2max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point2.x, v2: point2.y, v3: 1)
        e3max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point3.x, v2: point3.y, v3: 1)

        var maxT: CGFloat? = nil
        if let initialClipped = clipOnce(e3min, e1: e2min, e2: e1min, e3: e0min) {
            maxT = 1 - initialClipped
        }
        if let initialClipped = clipOnce(e3max, e1: e2max, e2: e1max, e3: e0max) {
            let clipped = 1 - initialClipped
            if let t = maxT {
                maxT = max(t, clipped)
            } else {
                maxT = clipped
            }
        }
        
        var clipMaxT: CGFloat
        if let maxT = maxT {
            clipMaxT = maxT
        } else {
            clipMaxT = 1
        }

        p01 = lerp(point0, point1: point1, t: clipMaxT)
        p12 = lerp(point1, point1: point2, t: clipMaxT)
        p23 = lerp(point2, point1: point3, t: clipMaxT)
        p012 = lerp(p01, point1: p12, t: clipMaxT)
        p123 = lerp(p12, point1: p23, t: clipMaxT)
        p0123 = lerp(p012, point1: p123, t: clipMaxT)
        (point0, point1, point2, point3) = (point0, p01, p012, p0123)

        return (point0, point1, point2, point3)
    }
}
