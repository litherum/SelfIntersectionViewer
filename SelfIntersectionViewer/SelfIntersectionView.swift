//
//  SelfIntersectionView.swift
//  SelfIntersectionViewer
//
//  Created by Litherum on 5/30/15.
//  Copyright (c) 2015 Litherum. All rights reserved.
//

import Cocoa
import Darwin

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
    var intersections: [CGPoint]

    enum ParticularPoint {
        case Point0
        case Point1
        case Point2
        case Point3
    }
    var draggedPoint: ParticularPoint?

    var selfIntersectionPoint: NSPoint?

    required init?(coder: NSCoder) {
        p0 = CGPointMake(100, 100)
        p1 = CGPointMake(450, 200)
        p2 = CGPointMake(13, 280)
        p3 = CGPointMake(283, 305)
        q0 = CGPointMake(275, 500)
        q1 = CGPointMake(100, 450)
        q2 = CGPointMake(400, 400)
        q3 = CGPointMake(225, 350)
        intersections = []
        super.init(coder: coder)
        selfIntersectionPoint = selfIntersectionPoint(p0, point1: p1, point2: p2, point3: p3)
        intersections = intersect((p0, p1, p2, p3), qs: (q0, q1, q2, q3))
    }

    func drawControlPoint(point: CGPoint) {
        NSBezierPath(ovalInRect: NSMakeRect(point.x - pointRadius, point.y - pointRadius, pointRadius * 2, pointRadius * 2)).stroke()
    }

    /*func drawLine(abc: (CGFloat, CGFloat, CGFloat)) {
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
    }*/

    override func drawRect(dirtyRect: NSRect) {
        NSBezierPath.setDefaultLineWidth(3)

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
        
        NSColor.redColor().set()
        if let selfIntersectionPoint = selfIntersectionPoint {
            drawControlPoint(selfIntersectionPoint)
        }

        NSColor.purpleColor().set()
        for point in intersections {
            drawControlPoint(point)
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
            println("Points: \(p0) \(p1) \(p2) \(p3)")
            selfIntersectionPoint = selfIntersectionPoint(p0, point1: p1, point2: p2, point3: p3)
            intersections = intersect((p0, p1, p2, p3), qs: (q0, q1, q2, q3))
            setNeedsDisplayInRect(self.bounds)
        }
    }

    func interpolatePoint(t: CGFloat, point0: CGPoint, point1: CGPoint, point2: CGPoint, point3: CGPoint) -> CGPoint {
        let oneMinusT = 1 - t
        let b0 = oneMinusT * oneMinusT * oneMinusT
        let b1 = 3 * t * oneMinusT * oneMinusT
        let b2 = 3 * t * t * oneMinusT
        let b3 = t * t * t
        return NSMakePoint(b0 * point0.x + b1 * point1.x + b2 * point2.x + b3 * point3.x, b0 * point0.y + b1 * point1.y + b2 * point2.y + b3 * point3.y)
    }

    func selfIntersectionPoint(point0: CGPoint, point1: CGPoint, point2: CGPoint, point3: CGPoint) -> CGPoint? {
        let a = 3 * (point1.x - point0.x)
        let b = 3 * (point0.x - 2 * point1.x + point2.x)
        let c = 3 * point1.x - point0.x - 3 * point2.x + point3.x
        let p = 3 * (point1.y - point0.y)
        let q = 3 * (point0.y - 2 * point1.y + point2.y)
        let r = 3 * point1.y - point0.y - 3 * point2.y + point3.y
        let cqbr = c * q - b * r
        let discriminant = -cqbr * cqbr * (3 * a * a * r * r - 4 * a * b * q * r - 6 * a * c * p * r + 4 * a * c * q * q + 4 * b * b * p * r - 4 * b * c * p * q + 3 * c * c * p * p)
        if discriminant <= 0 {
            return nil
        }
        let rest = -a * b * r * r + a * c * q * r + b * c * p * r + c * c * (-p) * q
        let s = 1 / (2 * cqbr * cqbr) * (-sqrt(discriminant) + rest)
        let t = 1 / (2 * cqbr * cqbr) * (sqrt(discriminant) + rest)
        if s < 0 || s >= 1 || t < 0 || t >= 1 {
            return nil
        }
        return interpolatePoint(s, point0: point0, point1: point1, point2: point2, point3: point3)
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

    func sgn(x: CGFloat) -> CGFloat {
        return x > 0 ? 1 : x < 0 ? -1 : 0
    }

    func findZeroes(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat) -> [CGFloat] {
        // https://www.particleincell.com/2013/cubic-line-intersection/
        let A = b / a
        let B = c / a
        let C = d / a
        let Q = (3 * B - A * A) / 9
        let R = (9 * A * B - 27 * C - 2 * A * A * A) / 54;
        let D = Q * Q * Q + R * R; // polynomial discriminant
        var t: [CGFloat] = []
        if D >= 0 { // complex or duplicate roots
            let squareRoot = sqrt(D)
            let S = sgn(R + squareRoot) * pow(abs(R + squareRoot), (1.0/3));
            let T = sgn(R - squareRoot) * pow(abs(R - squareRoot), (1.0/3));

            t.append(-A / 3 + (S + T)); // real root
            // discard complex roots
            if abs(sqrt(3) * (S - T) / 2) == 0 { // complex part of root pair
                t.append(-A / 3 - (S + T) / 2); // real part of complex root
                t.append(-A / 3 - (S + T) / 2); // real part of complex root
            }
        } else {
            let th = acos(R / sqrt(-Q * Q * Q));

            let squareRoot = sqrt(-Q)
            t.append(2 * squareRoot * cos(th / 3) - A / 3)
            t.append(2 * squareRoot * cos((th + 2 * CGFloat(M_PI)) / 3) - A / 3);
            t.append(2 * squareRoot * cos((th + 4 * CGFloat(M_PI)) / 3) - A / 3);
        }

        t = filter(t, {candidate -> Bool in
            return candidate >= 0 && candidate <= 1
        })

        return t
    }

    func bezierCoeffs(P0: CGFloat, P1: CGFloat, P2: CGFloat, P3: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        return (-P0 + 3*P1 + -3*P2 + P3, 3*P0 - 6*P1 + 3*P2, -3*P0 + 3*P1, P0)
    }

    func intersectLineWithBezier(point0: CGPoint, point1: CGPoint, point2: CGPoint, point3: CGPoint, l1: CGPoint, l2: CGPoint) -> [CGPoint] {
        let (A, B, C) = cross(l1.x, u2: l1.y, u3: 1, v1: l2.x, v2: l2.y, v3: 1)

        let bx = bezierCoeffs(point0.x, P1: point1.x, P2: point2.x, P3: point3.x)
        let by = bezierCoeffs(point0.y, P1: point1.y, P2: point2.y, P3: point3.y)

        var result: [CGPoint] = []

        for t in findZeroes(A * bx.0 + B * by.0, b: A * bx.1 + B * by.1, c: A * bx.2 + B * by.2, d: A * bx.3 + B * by.3 + C) {
            let candidate = CGPointMake(bx.0 * t * t * t + bx.1 * t * t + bx.2 * t + bx.3, by.0 * t * t * t + by.1 * t * t + by.2 * t + by.3)

            var s: CGFloat
            if (abs(l2.x - l1.x) > abs(l2.y - l1.y)) {
                s = (candidate.x - l1.x) / (l2.x - l1.x)
            } else {
                s = (candidate.y - l1.y) / (l2.y - l1.y)
            }

            if (t >= 0 && t <= 1.0 && s >= 0 && s <= 1.0) {
                result.append(candidate)
            }
        }

        return result
    }
    
    func subdivide(point0: CGPoint, point1: CGPoint, point2: CGPoint, point3: CGPoint, t: CGFloat) -> ((CGPoint, CGPoint, CGPoint, CGPoint), (CGPoint, CGPoint, CGPoint, CGPoint)) {
        var p01 = lerp(point0, point1: point1, t: t)
        var p12 = lerp(point1, point1: point2, t: t)
        var p23 = lerp(point2, point1: point3, t: t)
        var p012 = lerp(p01, point1: p12, t: t)
        var p123 = lerp(p12, point1: p23, t: t)
        var p0123 = lerp(p012, point1: p123, t: t)
        return ((point0, p01, p012, p0123), (p0123, p123, p23, point3))
    }
    
    func intersect(ps: (CGPoint, CGPoint, CGPoint, CGPoint), qs: (CGPoint, CGPoint, CGPoint, CGPoint)) -> [CGPoint] {
        return intersect((ps.0, ps.1, ps.2, ps.3, 0, 1), qs: (qs.0, qs.1, qs.2, qs.3, 0, 1), depth: 0)
    }

    func intersect(ps: (CGPoint, CGPoint, CGPoint, CGPoint, CGFloat, CGFloat), qs: (CGPoint, CGPoint, CGPoint, CGPoint, CGFloat, CGFloat), depth: UInt) -> [CGPoint] {
        if depth >= 13 {
            return [ps.0]
        }

        var approximatingLine = cross(ps.0.x, u2: ps.0.y, u3: 1, v1: ps.3.x, v2: ps.3.y, v3: 1)
        let epsilon = CGFloat(1)
        var distance1 = abs(dot(approximatingLine.0, u2: approximatingLine.1, u3: approximatingLine.2, v1: ps.1.x, v2: ps.1.y, v3: 1))
        var distance2 = abs(dot(approximatingLine.0, u2: approximatingLine.1, u3: approximatingLine.2, v1: ps.2.x, v2: ps.2.y, v3: 1))
        if distance1 < epsilon && distance2 < epsilon {
            return intersectLineWithBezier(qs.0, point1: qs.1, point2: qs.2, point3: qs.3, l1: ps.0, l2: ps.3)
        }
        approximatingLine = cross(qs.0.x, u2: qs.0.y, u3: 1, v1: qs.3.x, v2: qs.3.y, v3: 1)
        distance1 = abs(dot(approximatingLine.0, u2: approximatingLine.1, u3: approximatingLine.2, v1: qs.1.x, v2: qs.1.y, v3: 1))
        distance2 = abs(dot(approximatingLine.0, u2: approximatingLine.1, u3: approximatingLine.2, v1: qs.2.x, v2: qs.2.y, v3: 1))
        if distance1 < epsilon && distance2 < epsilon {
            return intersectLineWithBezier(ps.0, point1: ps.1, point2: ps.2, point3: ps.3, l1: qs.0, l2: qs.3)
        }
        
        if let (minT, maxT) = clip(ps.0, point1: ps.1, point2: ps.2, point3: ps.3, q0: qs.0, q1: qs.1, q2: qs.2, q3: qs.3) {
            let divided = subdivide(ps.0, point1: ps.1, point2: ps.2, point3: ps.3, t: minT)
            let divided2 = divided.1
            let adjustedMaxT = (maxT - minT) / (1 - minT)
            let divided3 = subdivide(divided.1.0, point1: divided.1.1, point2: divided.1.2, point3: divided.1.3, t: adjustedMaxT)
            let clipped = divided3.0
            let newStart = minT * (ps.5 - ps.4) + ps.4
            let newEnd = maxT * (ps.5 - ps.4) + ps.4
            if 1 - maxT + minT < 0.2 {
                if maxT - minT > qs.5 - qs.4 {
                    let subdivided = subdivide(clipped.0, point1: clipped.1, point2: clipped.2, point3: clipped.3, t: 0.5)
                    let part1 = subdivided.0
                    let part2 = subdivided.1
                    let midT = (newStart + newEnd) / 2
                    return intersect((part1.0, part1.1, part1.2, part1.3, newStart, midT), qs: qs, depth: depth + 1) + intersect((part2.0, part2.1, part2.2, part2.3, midT, newEnd), qs: qs, depth: depth + 1)
                } else {
                    let subdivided = subdivide(qs.0, point1: qs.1, point2: qs.2, point3: qs.3, t: 0.5)
                    let part1 = subdivided.0
                    let part2 = subdivided.1
                    let midT = (qs.4 + qs.5) / 2
                    return intersect(ps, qs: (part1.0, part1.1, part1.2, part1.3, qs.4, midT), depth: depth + 1) + intersect(ps, qs: (part2.0, part2.1, part2.2, part2.3, midT, qs.5), depth: depth + 1)
                }
            } else {
                return intersect(qs, qs: (clipped.0, clipped.1, clipped.2, clipped.3, newStart, newEnd), depth: depth + 1)
            }
        }
        return []
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

    func clip(point0: CGPoint, point1: CGPoint, point2: CGPoint, point3: CGPoint, q0: CGPoint, q1: CGPoint, q2: CGPoint, q3: CGPoint) -> (CGFloat, CGFloat)? {
        // Bezier Clipping. http://cagd.cs.byu.edu/~557/text/ch7.pdf
        let (l0, l1, l2) = cross(q0.x, u2: q0.y, u3: 1, v1: q3.x, v2: q3.y, v3: 1)
        let c1 = -l0 * q1.x - l1 * q1.y
        let c2 = -l0 * q2.x - l1 * q2.y
        let lmin = (-l0, -l1, -min(min(l2, c1), c2))
        let lmax = (l0, l1, max(max(l2, c1), c2))

        let e0min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point0.x, v2: point0.y, v3: 1)
        let e1min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point1.x, v2: point1.y, v3: 1)
        let e2min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point2.x, v2: point2.y, v3: 1)
        let e3min = dot(lmin.0, u2: lmin.1, u3: lmin.2, v1: point3.x, v2: point3.y, v3: 1)
        let e0max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point0.x, v2: point0.y, v3: 1)
        let e1max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point1.x, v2: point1.y, v3: 1)
        let e2max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point2.x, v2: point2.y, v3: 1)
        let e3max = dot(lmax.0, u2: lmax.1, u3: lmax.2, v1: point3.x, v2: point3.y, v3: 1)

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

        return (clipMinT, clipMaxT)
    }
}
