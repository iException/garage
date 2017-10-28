//
//  UIImage+Garage.swift
//  Garage
//
//  Created by Yiming Tang on 10/27/17.
//  Copyright © 2017 Baixing. All rights reserved.
//

import UIKit

// MARK: - Alpha
extension UIImage {
    /// Returns whether the image contains an alpha component.
    var gar_containsAlphaComponent: Bool {
        let alphaInfo = cgImage?.alphaInfo

        return (
            alphaInfo == .first ||
            alphaInfo == .last ||
            alphaInfo == .premultipliedFirst ||
            alphaInfo == .premultipliedLast
        )
    }

    /// Returns whether the image is opaque.
    var gar_isOpaque: Bool { return !gar_containsAlphaComponent }
}


// MARK: - Scaling

extension UIImage {
    func gar_imageScaled(to size: CGSize) -> UIImage {
        assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")

        UIGraphicsBeginImageContextWithOptions(size, gar_isOpaque, 0.0)
        draw(in: CGRect(origin: .zero, size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()

        return scaledImage
    }

    func gar_imageAspectScaled(toFit size: CGSize) -> UIImage {
        assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")

        let imageAspectRatio = self.size.width / self.size.height
        let canvasAspectRatio = size.width / size.height

        var resizeFactor: CGFloat

        if imageAspectRatio > canvasAspectRatio {
            resizeFactor = size.width / self.size.width
        } else {
            resizeFactor = size.height / self.size.height
        }

        let scaledSize = CGSize(width: self.size.width * resizeFactor, height: self.size.height * resizeFactor)
        let origin = CGPoint(x: (size.width - scaledSize.width) / 2.0, y: (size.height - scaledSize.height) / 2.0)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: origin, size: scaledSize))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()

        return scaledImage
    }

    func gar_imageAspectScaled(toFill size: CGSize) -> UIImage {
        assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")

        let imageAspectRatio = self.size.width / self.size.height
        let canvasAspectRatio = size.width / size.height

        var resizeFactor: CGFloat

        if imageAspectRatio > canvasAspectRatio {
            resizeFactor = size.height / self.size.height
        } else {
            resizeFactor = size.width / self.size.width
        }

        let scaledSize = CGSize(width: self.size.width * resizeFactor, height: self.size.height * resizeFactor)
        let origin = CGPoint(x: (size.width - scaledSize.width) / 2.0, y: (size.height - scaledSize.height) / 2.0)

        UIGraphicsBeginImageContextWithOptions(size, gar_isOpaque, 0.0)
        draw(in: CGRect(origin: origin, size: scaledSize))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()

        return scaledImage
    }
}
