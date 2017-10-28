//
//  Vehicle.swift
//  Garage
//
//  Created by Xiang Li on 28/10/2017.
//  Copyright © 2017 Baixing. All rights reserved.
//

import UIKit
import RealmSwift
import Realm
import Foundation
import SKPhotoBrowser

class Vehicle: Object {
    @objc dynamic var imageData: Data?
    var contentMode: UIViewContentMode = .scaleAspectFill
    var index: Int = 0
    
    var image: UIImage? {
        get {
            if let imageData = imageData {
                return UIImage(data: imageData)
            }
            return nil
        }
    }
    
    // MARK: - Initializer
    
    required init() {
        self.imageData = nil
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        // wtf?
        super.init(realm: realm, schema: schema)
    }
    
    init(image: UIImage) {
        self.imageData = UIImagePNGRepresentation(image)
        super.init()
    }
}


