//
//  DefaultMecroSetting.swift
//  PhotoBrowser
//
//  Created by Zonyet on 2018/1/10.
//  Copyright © 2018年 Zonyet. All rights reserved.
//

import Foundation
import UIKit

let PhotoBrowersWillDismissNotification = "PhotoBrowersWillDismissNotification"
let PhotoBrowersDidDismissNotification = "PhotoBrowersDidDismissNotification"
let PhotoBrowersPhotoDownloadFinishedNotification = "PhotoBrowersPhotoDownloadFinishedNotification"

let Screen_W = UIScreen.main.bounds.width
let Screen_H = UIScreen.main.bounds.height

let IS_IPhone = (UIDevice.current.userInterfaceIdiom == .phone)
let IS_IPhone_X = IS_IPhone && (Screen_H == 812)
let IPhone_X_Bottom = 34
let IPhone_X_StatusBar = 44
let Bottom_Margin = IS_IPhone_X ? IPhone_X_Bottom : 0



func moveSizeToCenter(size: CGSize) -> CGRect {
    return CGRect(x: Screen_W/2.0 - size.width/2.0, y: Screen_W/2.0 - size.height/2.0, width: size.width, height: size.height)
}
