//
//  ToolsView.swift
//  PhotoBrowser
//
//  Created by Zonyet on 2018/1/10.
//  Copyright © 2018年 Zonyet. All rights reserved.
//

import Foundation
import UIKit

/// 加载图片指示框
class LoadingView: UIView {
    let second = 0.02
    lazy var timer = Timer.scheduledTimer(withTimeInterval: second, repeats: true) { [unowned self] (time) in
        self.transform = CGAffineTransform.init(rotationAngle: 0.2)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let layer1 = CAShapeLayer.init()
        layer1.makeCircle(rect: frame, begAngle: 0, fillColor: UIColor.clear.cgColor, strokeColor: UIColor.black.cgColor)
        self.layer.addSublayer(layer1)
        let layer2 = CAShapeLayer.init()
        layer2.makeCircle(rect: frame, begAngle: CGFloat(2 * Double.pi)*0.85, fillColor: UIColor.clear.cgColor, strokeColor: UIColor.white.cgColor)
        self.layer.addSublayer(layer2)
        self.backgroundColor = UIColor.clear
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }
    
    deinit {
        timer.invalidate()
    }
    /*
    class func showHud(text: NSString, to: UIView?, delay: TimeInterval) -> UILabel? {
        guard to != nil else {
            return
        }
        
        let label = UILabel.init(frame: <#T##CGRect#>)
    }*/
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        RunLoop.current.add(timer, forMode: .commonModes)
        timer.fire()
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        timer.invalidate()
    }
    
}

class PopOptionView: UIView {
    
}



extension CAShapeLayer {
    func makeCircle(rect: CGRect, begAngle: CGFloat, fillColor: CGColor, strokeColor: CGColor) {
        let radius = rect.size.width/2
        let arcCenter = CGPoint(x: rect.size.width/2, y: rect.size.width/2)
        let endAngle = CGFloat(2 * Double.pi)
        
        let path = UIBezierPath.init(arcCenter: arcCenter, radius: radius, startAngle: begAngle, endAngle: endAngle, clockwise: true)
        self.path = path.cgPath
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.lineWidth = 5
    }
}


extension UIView {
    var height: CGFloat {
        set {
            _ = self.height(setH: newValue)
        }
        get {
            return self.bounds.height
        }
    }
    
    var width: CGFloat {
        set {
            _ = self.width(setW: newValue)
        }
        get {
            return self.bounds.width
        }
    }
    
    var bottom: CGFloat {
        set {
            var rect = self.frame
            rect.origin.y = newValue - rect.size.height
            self.frame = rect
        }
        get {
            return self.bounds.width
        }
    }
    
    func height(setH: CGFloat) -> Self{
        let rect = self.frame
        self.frame = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: setH)
        
        return self
    }
    
    func width(setW: CGFloat) {
        let rect = self.frame
        self.frame = CGRect(x: rect.origin.x, y: rect.origin.y, width: setW, height: rect.size.height)
    }
    
    func centerY(setY: CGFloat) {
        let point = self.center
        self.center = CGPoint(x: point.x, y: setY)
    }
    
}
