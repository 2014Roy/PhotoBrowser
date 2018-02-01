//
//  PhotoBrowserView.swift
//  PhotoBrowser
//
//  Created by Zonyet on 2018/1/10.
//  Copyright © 2018年 Zonyet. All rights reserved.
//

import Foundation
import UIKit


/// 单元cell  处理单击 和 双击 手势
class PhotoCollectionViewCell: UICollectionViewCell {
    var zoomScrollView: ZoomScrollView?
    var model: ScrollViewStatusModel? {
        didSet {
            zoomScrollView?.model = model
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = UIColor.clear
        self.initSubview()

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gesture:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(gesture:)))
        self.addGestureRecognizer(tap)
        tap.require(toFail: doubleTap)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }
    
    //MARK: method
    func initSubview() {
        self.zoomScrollView = ZoomScrollView(frame: CGRect(x: 10, y: 0, width: Screen_W, height: Screen_H))
        self.contentView.addSubview(self.zoomScrollView!)
    }
    
    @objc func tap(gesture: UITapGestureRecognizer) -> Void {
        let point = gesture.location(in: zoomScrollView?.imageView)
        self.zoomScrollView?.handleSingleTap(point: point)
    }
    
    @objc func doubleTap(gesture: UIGestureRecognizer) -> Void {
        let point = gesture.location(in: zoomScrollView?.imageView)
        guard (zoomScrollView?.imageView.bounds)!.contains(point) else {
            return
        }
        self.zoomScrollView?.handleDoubleTap(point: point)
    }
    
    func showAnimation(model: ScrollViewStatusModel, completionBlock:@escaping () -> Void) -> Void {
        self.zoomScrollView?.showImageView(model: model, completionBlock: completionBlock)
    }
}

class PhotoBrowersView : UIView {
    lazy var pageControl: UIPageControl = {
       let page = UIPageControl(frame: CGRect(x: 0, y: 0, width: Screen_W, height: 10))
        page.currentPageIndicatorTintColor = UIColor.white
        page.pageIndicatorTintColor = UIColor.gray
        page.numberOfPages = dataArr.count
        page.currentPage = 0
        
        return page
    }()
    var collectionView: UICollectionView = {
       let flowlayout = UICollectionViewFlowLayout()
        flowlayout.scrollDirection = .horizontal
        flowlayout.minimumInteritemSpacing = 0
        flowlayout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: CGRect(x: -10, y: 0, width: Screen_W + 20, height: Screen_H), collectionViewLayout: flowlayout)
        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceVertical = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        
        return collectionView
    }()
    
    var dataArr = [Any]()
    var modelArr = [ScrollViewStatusModel]()
    
    var startPoint: CGPoint?
    var startCenter: CGPoint?
    var zoomScale: CGFloat? = 1
    
    var preloading: Bool = true
    var isShowing: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(willDismiss), name: NSNotification.Name(rawValue: PhotoBrowersWillDismissNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scrollViewDidScroll(_:)), name: NSNotification.Name(rawValue: PhotoBrowersPhotoDownloadFinishedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDismiss), name: NSNotification.Name(rawValue: PhotoBrowersDidDismissNotification), object: nil)

        self.backgroundColor = UIColor.black
        collectionView.delegate = self
        collectionView.dataSource = self
        self.addSubview(collectionView)
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(didMove(gesture:)))
        self.addGestureRecognizer(panGesture)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    //MARK: method
    func showImages(urls: [Any], index: Int) {
        self.dataArr = urls
        self.pageControl.bottom = Screen_H - 50
        self.pageControl.isHidden = self.dataArr.count == 1
        self.modelArr.removeAll()
        for (n, obj) in self.dataArr.enumerated() {
            let model = ScrollViewStatusModel()
            model.showPop = n == index
            model.isShowing = n == index
            model.index = NSNumber.init(value: n)
            //解析
            if let temp = obj as? UIImage {
                model.currentPageImage = temp
            }
            if let temp = obj as? NSURL {
                model.url = temp
            }
            self.modelArr.append(model)
        }
        
        self.collectionView.alwaysBounceHorizontal = urls.count == 1
        self.collectionView.reloadData()
        self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: false)
    }
    
    @objc func didMove(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let distance = gesture.translation(in: self)
        let cell = self.collectionView.cellForItem(at: IndexPath(item: self.pageControl.currentPage, section: 0)) as? PhotoCollectionViewCell
        switch gesture.state {
        case .began:
            self.startPoint = location
            self.zoomScale = cell?.zoomScrollView?.zoomScale
            self.startCenter = cell?.zoomScrollView?.imageView.center
        case .changed:
            cell?.zoomScrollView?.isMoving = true
            let percent = 1 - fabsf(Float(distance.y))/Float(self.frame.size.height)
            var scale = CGFloat(max(percent, 0.3))
            if let s = self.zoomScale {
                scale = scale * s
            }
            let affineTrans = CGAffineTransform.init(scaleX: CGFloat(scale), y: CGFloat(scale))
            //设置imageV的center和处理scale
            cell?.zoomScrollView?.imageView.transform = affineTrans
            cell?.zoomScrollView?.imageView.center = CGPoint(x: self.startCenter!.x + distance.x, y: self.startCenter!.y + distance.y)
            if let s = self.zoomScale {
                self.backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: CGFloat(scale)/s)
            }
        case .ended, .cancelled:
            if fabsf(Float(distance.y)) > 100 {
                cell?.zoomScrollView?.handleSingleTap(point: CGPoint.zero)
            } else {
                let affineTrans = CGAffineTransform(scaleX: self.zoomScale!, y: self.zoomScale!)
                UIView.animate(withDuration: 0.25, animations: {
                    cell?.zoomScrollView?.imageView.transform = affineTrans
                    cell?.zoomScrollView?.imageView.center = self.startCenter!
                    self.backgroundColor = UIColor.black
                }, completion: { finish in
                    if finish {
                        cell?.zoomScrollView?.isMoving = false
                        cell?.zoomScrollView?.layoutSubviews()
                    }
                })
            }
        default:
            print("do nothing")
        }
    }
    
    @objc func willDismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.pageControl.alpha = 0
        }) { finish in
            if finish {self.pageControl.removeFromSuperview()}
        }
        for obj in self.modelArr {
            if let op = obj.opreation {
                op.cancel()
            }
        }
    }
    
    @objc func didDismiss() {
        self.removeFromSuperview()
    }
    
    func refreshPageControl(page: Int) {
        guard page != self.pageControl.currentPage else {
            return
        }
        self.pageControl.currentPage = page
        
        //重置model
        do {
            for obj in self.modelArr {
                obj.isShowing = false
            }
            let model = self.modelArr[page]
            model.isShowing = true
        }
        
        let cell = self.collectionView.cellForItem(at: IndexPath(item: page, section: 0))
        //
    }
}

extension PhotoBrowersView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageW = self.collectionView.width
        let page = floorf(Float((self.collectionView.contentOffset.x - pageW/2) / pageW)) + 1
        self.refreshPageControl(page: Int(page))
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Screen_W + 20, height: Screen_H)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let ptotoCell = cell as! PhotoCollectionViewCell
        let model = self.modelArr[indexPath.item]
        model.currentPageImage = model.currentPageImage  ?? nil
        
        if model.showPop {
            ptotoCell.showAnimation(model: model, completionBlock: { [unowned self] in
                self.isShowing = true
                model.showPop = false
            })
        }
        ptotoCell.model = model
        guard self.isShowing else {
            return
        }
        
        if let array = model.currentPageImage?.images?.count {
            if array > 0 {
                self.scrollViewDidScroll(collectionView)
            }
        }
        //图片判断
        let obj = self.dataArr.first as! UIImage
        if obj.isKind(of: UIImage.self) {
            return
        }
        //预加载
        guard self.preloading else {
            return
        }
        
        DispatchQueue.global().async {
            for obj in self.modelArr {
                obj.shouldCancel = true
            }
            
            let leftIndex = (model.index!.intValue - 1) >= 0 ? (model.index!.intValue - 1) : 0
            let rightIndex = ((model.index!.intValue + 1) < self.modelArr.count) ? model.index!.intValue + 1 : self.modelArr.count - 1
            for i in [leftIndex...rightIndex] {
                model.shouldCancel = false
                print(i.lowerBound)
                if model.index!.intValue == i.lowerBound {
                    continue
                }
                let preloadingModel = self.modelArr[i.lowerBound]
                preloadingModel.shouldCancel = false
                preloadingModel.currentPageImage = model.currentPageImage  ?? nil
                if preloadingModel.currentPageImage != nil {
                    continue
                }
                preloadingModel.loadImage()
            }
            
            //判断是否继续加载
            var downloadCount = 0
            for obj in self.modelArr {
                if obj.shouldCancel && obj.opreation != nil {
                    obj.opreation?.cancel()
                    obj.opreation = nil
                }
                if obj.currentPageImage != nil {
                    downloadCount = downloadCount + 1
                }
            }
            
            if downloadCount == self.modelArr.count {
                self.preloading = false
            }

        }
    }
}
