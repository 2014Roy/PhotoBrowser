//
//  PhotoBrowserManager.swift
//  PhotoBrowser
//
//  Created by Zonyet on 2018/1/11.
//  Copyright © 2018年 Zonyet. All rights reserved.
//

import Foundation
import UIKit

class PhotoItem: NSObject {
    var urlStr: String?
    var frame: CGRect = CGRect.zero
    var placehodelSize: CGSize = CGSize.zero
    var placehodelImage: UIImage?
    var localImage: UIImage?
    
    init(frame: CGRect, localImage: UIImage?, urlStr: String?) {
        super.init()
        self.frame = frame
        self.localImage = localImage
        self.urlStr = urlStr
    }
    
}

class PhotoBrowersManager: NSObject {
    var urls: [String]? = [String]()
    var frames: [CGRect]? = [CGRect]()
    var images: [UIImage]? = [UIImage]()
    var titles: [String]?
    
    var currentPage: Int = 0
    var currentShowImage: UIImage?
    var preloading: Bool = false
    
    var placeholdImageBlock: ((IndexPath) -> Void)?
    var placeholdImageSizeBlock: ((UIImage, IndexPath) -> CGSize)?
    var titleBlock: ((UIImage, IndexPath, String) -> Void)?
    var longPressBlock: ((UIImage, IndexPath) -> UIView)?
    
    var willDismissBlock: (() -> Void)?
    var didDismissBlock: (() -> Void)?
    var errImage: UIImage?
    
    var imageViewSuper: UIView?
    var photoBrowsersView: PhotoBrowersView?
    var collectionView: UICollectionView?
    
    static let defaultManager = PhotoBrowersManager()
    
    var requestQueue: OperationQueue = {
        let queue = OperationQueue.init()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(willDismiss), name: NSNotification.Name(rawValue: PhotoBrowersWillDismissNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDismiss), name: NSNotification.Name(rawValue: PhotoBrowersDidDismissNotification), object: nil)

    }
    
    //MARK: method
    @objc func willDismiss() {
        if let block = self.willDismissBlock {
            block()
        }
        self.willDismissBlock = nil
    }
    
    @objc func didDismiss() {
        if let block = self.didDismissBlock {
            block()
        }
        self.didDismissBlock = nil
        self.preloading = true
    }
    
    func showImage(items: [PhotoItem], index: Int, superV: UIView) {
        guard items.count > 0 else {
            return
        }
        clearData(superV: self.photoBrowsersView, urls: self.urls, frames: self.frames, images: self.images)
        for photoItem in items {
            if let item = photoItem.localImage {
                self.images?.append(item)
            }
            if !photoItem.frame.equalTo(CGRect.zero) {
                self.frames?.append(photoItem.frame)
            } else {
                self.frames?.append(CGRect.zero)
            }
            if let url = photoItem.urlStr {
                self.urls?.append(url)
            }
        }
        assert(self.images?.count == self.frames?.count, "数量必须相同")
        
        self.currentPage = index
        self.imageViewSuper = superV
        let browserView = PhotoBrowersView(frame: UIScreen.main.bounds)
        browserView.showImages(urls: self.images!, index: index)
        UIApplication.shared.keyWindow?.addSubview(browserView)
        self.photoBrowsersView = browserView
    }
    
    func clearData(superV: UIView?, urls: [String]?, frames: [CGRect]?, images: [UIImage]?) {
        self.urls?.removeAll()
        self.frames?.removeAll()
        self.images?.removeAll()
        self.photoBrowsersView?.removeFromSuperview()
    }
}
