//
//  CollectionSafeIndex.swift
//  Garage
//
//  Created by Xiang Li on 28/10/2017.
//  Copyright © 2017 Baixing. All rights reserved.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
