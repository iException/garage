//
//  VehicleCollectionViewCell.swift
//  Garage
//
//  Created by Xiang Li on 28/10/2017.
//  Copyright © 2017 Baixing. All rights reserved.
//

import UIKit

class VehicleCollectionViewCell: UICollectionViewCell {
    lazy var imageView: UIImageView = {
       var imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(imageView)
        self.clipsToBounds = true;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - UICollectionView
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageView.image = nil
    }
    
    // MARK: - UIView
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.contentView.bounds
    }
}
