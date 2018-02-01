//
//  TapImageView.swift
//  PhotoBrowser
//
//  Created by Zonyet on 2018/1/10.
//  Copyright © 2018年 Zonyet. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

class ScrollViewStatusModel: NSObject {
    var scale: NSNumber?
    var contentOffset: CGPoint?
    var currentPageImage: UIImage?
    var url: NSURL?
    var opreation: SDWebImageDownloaderOperation?
    var index: NSNumber?

    var isShowing: Bool = false
    var showPop: Bool = false
    var shouldCancel: Bool = false
    
    var loadImageCompletedBlock : ((_ loadModel: ScrollViewStatusModel, _ image: UIImage, _ data: Data, _ error: Error, _ finished: Bool, _ imageUrl: NSURL?) -> Void)?
    
    override init() {
        super.init()
        self.scale = NSNumber(value: 1)
        self.contentOffset = CGPoint(x: 0, y: 0)
    }
    //MARK:
    func loadImageWithCompletedBlock(compltedBlock:@escaping (_ loadModel: ScrollViewStatusModel, _ image: UIImage, _ data: Data, _ error: Error, _ finished: Bool, _ imageUrl: NSURL?) -> Void) {
        loadImageCompletedBlock = compltedBlock
        loadImage()
    }
    
    func loadImage() {
        guard self.opreation != nil else {
            return
        }
        self.opreation = SDWebImageManager.shared().loadImage(with: self.url! as URL, options: SDWebImageOptions(rawValue: 0), progress: nil, completed: {[unowned self] (image, data, error, cacheType, finish, imageUrl) in
            DispatchQueue.main.async {
                self.opreation = nil
                guard image != nil else {
                    return
                }
                if let block = self.loadImageCompletedBlock {
                    block(self, image!, data!, error!, finish, imageUrl! as NSURL)
                }
                self.currentPageImage = image
            }
        }) as? SDWebImageDownloaderOperation
    }
}

class TapImageView: UIImageView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        self.contentMode = .scaleAspectFit
        self.clipsToBounds = true
        let gesture = UILongPressGestureRecognizer.init(target: self, action: #selector(longPress))
        self.addGestureRecognizer(gesture)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }
    
    @objc func longPress() {
        
    }
}
