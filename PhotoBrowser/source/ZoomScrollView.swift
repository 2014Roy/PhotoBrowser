//
//  ZoomScrollView.swift
//  PhotoBrowser
//
//  Created by Zonyet on 2018/1/10.
//  Copyright © 2018年 Zonyet. All rights reserved.
//

import Foundation
import UIKit

class ZoomScrollView: UIScrollView {
    let scrollViewMinZoomScale: CGFloat = 1.0;
    let scrollViewMaxZoomScale: CGFloat = 3.0;
    var isMoving: Bool = false
    var imageSize: CGSize = CGSize.zero
    var oldFrame: CGRect = CGRect.zero
    
    var model: ScrollViewStatusModel? {
        didSet {
            self.removeAnimation(layer: self.imageView.layer)
            let mgr = PhotoBrowersManager.defaultManager
            if let image = model?.currentPageImage {
                self.loadingV.removeFromSuperview()
                self.refreshScrollView(image: image)
                self.imageView.image = image
                self.maximumZoomScale = scrollViewMaxZoomScale
            } else {
                self.maximumZoomScale = scrollViewMinZoomScale
                loadingV = LoadingView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                let size = self.placehodelImage().size
                if size.equalTo(CGSize.zero) {
                    self.refreshScrollView(image: self.placehodelImage())
                } else {
                    self.imageView.frame = moveSizeToCenter(size: size)
                }
                
                self.imageView.image = self.placehodelImage()
                model?.loadImageWithCompletedBlock(compltedBlock: {[unowned self] (loadModel, image, data, error, finish, imageUrl) in
                    self.loadingV.removeFromSuperview()
                    self.maximumZoomScale = self.scrollViewMaxZoomScale
                    self.model?.currentPageImage = image
                    let cells = mgr.collectionView?.visibleCells
                    for cell in cells! {
                        let visibleModel = cell.value(forKey: "model") as? ScrollViewStatusModel
                        if self.model?.index?.intValue == visibleModel?.index?.intValue {
                            self.refreshCell(model: self.model!, image: image, data: data)
                        }
                    }
                })
            }
            
            self.zoomScale = CGFloat(truncating: (model?.scale)!)
            self.contentOffset = (model?.contentOffset)!
        }
    }
    var imageView = TapImageView(frame: CGRect.zero)
    var loadingV = LoadingView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.delegate = self
        self.alwaysBounceVertical = true
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.panGestureRecognizer.delegate = self;
        self.minimumZoomScale = scrollViewMinZoomScale
        self.addSubview(self.imageView)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect(x: 0, y: 0, width: Screen_W, height: Screen_H))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard !self.isMoving else {
            return
        }
        
        let boundsSize = self.bounds.size;
        var frameToCenter =  self.imageView.frame;
        
        if (frameToCenter.size.width < boundsSize.width) {
            frameToCenter.origin.x = CGFloat(floorf(Float(boundsSize.width - frameToCenter.size.width)/2.0));
        } else {
            frameToCenter.origin.x = 0;
        }
        
        // Vertically
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = CGFloat(floorf(Float(boundsSize.height - frameToCenter.size.height)/2.0));
        } else {
            frameToCenter.origin.y = 0;
        }
        // Center
        if (!self.imageView.frame.equalTo(frameToCenter)){
            self.imageView.frame = frameToCenter;
        }
    }
    
    // MARK: method
    func refreshCell(model: ScrollViewStatusModel, image: UIImage, data: Data) {
        self.imageView.image = model.currentPageImage
        self.refreshScrollView(image: model.currentPageImage!)
        let size = self.placehodelImage().size
        if size.equalTo(CGSize.zero) {
            self.fadeAnimation(layer: self.imageView.layer, curver: .linear, duration: 0.25)
        } else {
            let imageViewFrame = self.imageView.frame
            self.imageView.frame = moveSizeToCenter(size: size)
            UIView.animate(withDuration: 0.25, animations: {
                self.imageView.frame = imageViewFrame
            })
        }
    }
    
    func showImageView(model: ScrollViewStatusModel, completionBlock: @escaping () -> Void) {
        self.model = model
        if model.currentPageImage == nil {
            model.currentPageImage = placehodelImage()
        }
        showAnimation(image: model.currentPageImage, completionBlock: completionBlock)
    }
    
    func showAnimation(image: UIImage?, completionBlock:@escaping () -> Void) {
        let mgr = PhotoBrowersManager.defaultManager
        let imageRect = mgr.frames![mgr.currentPage]
        let rect = mgr.imageViewSuper?.convert(imageRect, to: UIApplication.shared.keyWindow)
        self.oldFrame = rect!
        var photoImageViewFrame = CGRect.zero
        if let currentImage = self.model?.currentPageImage {
            self.refreshScrollView(image: currentImage)
            photoImageViewFrame = self.imageView.frame
        } else {
            photoImageViewFrame = moveSizeToCenter(size: self.placehodelImage().size)
        }
        
        self.isMoving = true
        self.imageView.image = nil
        self.imageView.image = image
        self.setNeedsLayout()
        self.imageView.frame = self.oldFrame
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.imageView.frame = photoImageViewFrame
        }) { (finish) in
            if finish {
                self.isMoving = false
                self.layoutSubviews()
                completionBlock()
            }
        }
    }
    
    func fadeAnimation(layer: CALayer, curver: UIViewAnimationCurve, duration: TimeInterval) {
        guard duration > 0 else {
            return
        }

        var mediaFunction = kCAMediaTimingFunctionLinear
        switch (curver) {
            case .easeInOut:
                mediaFunction = kCAMediaTimingFunctionEaseInEaseOut;
            case .easeIn:
                mediaFunction = kCAMediaTimingFunctionEaseIn;
            case .easeOut:
                mediaFunction = kCAMediaTimingFunctionEaseOut;
            case .linear:
                mediaFunction = kCAMediaTimingFunctionLinear;
        }
        
        let transition = CATransition.init();
        transition.duration = duration;
        transition.timingFunction = CAMediaTimingFunction.init(name: mediaFunction);
        transition.type = kCATransitionFade;
        layer.add(transition, forKey: "my.fade")
    }
    
    func removeAnimation(layer: CALayer) {
        layer.removeAnimation(forKey: "my.fade")
    }
    
    func refreshScrollView(image: UIImage) {
        self.zoomScale = scrollViewMinZoomScale
        self.imageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: 0)
        if (image.size.height/image.size.width > self.bounds.height/self.bounds.width) {
            let height = floor(image.size.height/(image.size.width/self.bounds.width))
             _ = self.imageView.height(setH: height)
        }else {
            let height = image.size.height/image.size.width * self.bounds.width
             _ = self.imageView.height(setH: height)
            self.imageView.centerY(setY: self.bounds.height/2)
        }
        if (self.imageView.height > self.height && self.imageView.height - self.height <= 1) {
            self.imageView.height = self.height
        }
        
        self.contentSize = CGSize(width: self.width, height: max(self.imageView.height, self.height))
        self.contentOffset = CGPoint.zero
        
        if (self.imageView.height > self.height) {
            self.alwaysBounceVertical = true;
        } else {
            self.alwaysBounceVertical = false
        }
    }
    
    func placehodelImage() -> UIImage {
        return UIImage()
    }
    
    //MARK: gesture
    func handleSingleTap(point: CGPoint) {
        loadingV.removeFromSuperview()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PhotoBrowersWillDismissNotification), object: nil)
        let manager = PhotoBrowersManager.defaultManager
        let imageVRect = manager.frames![manager.currentPage]
        let oldFrame = manager.imageViewSuper?.convert(imageVRect, to: UIApplication.shared.keyWindow)
        self.isMoving = true
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            self.zoomScale = self.scrollViewMinZoomScale
            self.contentOffset = CGPoint.zero
            self.imageView.frame = oldFrame!
            self.imageView.contentMode = .scaleAspectFill
            self.imageView.clipsToBounds = true
//            self.imageView.image = self.model?.currentPageImage
            manager.collectionView?.superview?.backgroundColor = UIColor.clear
        }) { (finish) in
            if finish {
                UIView.animate(withDuration: 0.15, delay: 0.25, options: .curveLinear, animations: {
                    self.imageView.alpha = 0
                }, completion: { (finish) in
                    if finish {
                        self.imageView.removeFromSuperview()
                        self.removeFromSuperview()
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PhotoBrowersDidDismissNotification), object: nil)
                    }
                })
            }
        }
    }
    
    func handleDoubleTap(point: CGPoint) {
        if (self.maximumZoomScale == self.minimumZoomScale) {
            return;
        }
        
        if (self.zoomScale != self.minimumZoomScale) {
            self.setZoomScale(self.minimumZoomScale, animated: true)
        } else {
            let newZoomScale = self.maximumZoomScale
            let xsize = self.bounds.size.width/newZoomScale
            let ysize = self.bounds.size.height/newZoomScale
            self.zoom(to: CGRect(x: point.x - xsize/2, y: point.y - ysize/2, width: xsize, height: ysize), animated: true)
        }
    }
}

extension ZoomScrollView: UIScrollViewDelegate, UIGestureRecognizerDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard (self.model?.isShowing)! else {
            return
        }
        
        self.model?.scale = scrollView.zoomScale as NSNumber;
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if (self.imageView.height > Screen_H) {
            //todo:
        }
    }
}


