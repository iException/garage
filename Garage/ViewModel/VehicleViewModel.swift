//
//  VehicleViewModel.swift
//  Garage
//
//  Created by Xiang Li on 28/10/2017.
//  Copyright © 2017 Baixing. All rights reserved.
//

import UIKit
import SKPhotoBrowser

class VehicleViewModel: NSObject {
    var contentMode: UIViewContentMode = .scaleAspectFill
    var index: Int = 0
    var image: UIImage?
    
    init(image: UIImage) {
        self.image = image
    }
}

extension VehicleViewModel: SKPhotoProtocol {
    func loadUnderlyingImageAndNotify() {
    }
    
    func checkCache() {
    }
    
    var underlyingImage: UIImage! {
        get {
            return image
        }
    }
    
    var caption: String! {
        get {
            return "some text"
        }
    }
}
