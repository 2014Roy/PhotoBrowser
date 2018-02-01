//
//  ViewController.swift
//  PhotoBrowser
//
//  Created by Zonyet on 2018/1/10.
//  Copyright © 2018年 Zonyet. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var imageViews: [UIImageView]!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        for (index, imv) in imageViews.enumerated() {
            let tap = UITapGestureRecognizer(target: self, action: #selector(tap(gesture:)))
            imv.addGestureRecognizer(tap)
            let image = UIImage(named: "ww\(index + 1)")
            imv.image = image
            imv.tag = index
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func tap(gesture: UITapGestureRecognizer)  {
        //test local
        var items = [PhotoItem]()
        for imv in self.imageViews {
            let item = PhotoItem(frame: imv.frame, localImage: imv.image, urlStr: "")
            items.append(item)
        }

        PhotoBrowersManager.defaultManager.showImage(items: items, index: (gesture.view?.tag)!, superV: self.view)
        
        //test network
        
    }
}

