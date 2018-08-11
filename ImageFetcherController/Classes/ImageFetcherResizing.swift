//
//  ImageFetcherResizing.swift
//  Feed
//
//  Created by Jason Howlin on 6/6/18.
//  Copyright © 2018 Howlin. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

func scaleSourceToFit(source:CGRect, target:CGRect) -> CGRect {
    let newSize = scaleSourceSizeToFitTarget(source: source.size, target: target.size)
    return CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
}

func scaleSourceSizeToFitTarget(source:CGSize, target:CGSize) -> CGSize {
    var scale:CGFloat = 0
    if source.width < source.height {
        scale = target.width / source.width
    } else if source.width > source.height {
        scale = target.height / source.height
    } else {
        scale = max(target.height, target.width) / max(source.height, source.width)
    }
    let newSize = source.scaled(scaleFactor: scale)
    return newSize
}

extension CGSize {
    var isLandscape:Bool {
        return width >= height
    }
    
    var isPortrait:Bool {
        return height >= width
    }
    
    var aspectRatio:CGFloat {
        return ((self.width / self.height) * 100).rounded() / 100
    }
    
    public var scaledForScreen:CGSize {
        return scaled(scaleFactor: UIScreen.main.scale)
    }

    func scaled(scaleFactor:CGFloat) -> CGSize {
        return CGSize(width: self.width * scaleFactor, height: self.height * scaleFactor)
    }
}

func resizeImageData(data:Data, targetSize:CGSize, sourceSize:CGSize) -> UIImage? {
    var image:UIImage? = nil

    // Scale the image up to keep the aspect ratio, but completely fit exactly or exceed the target size
    let scaledSize = scaleSourceSizeToFitTarget(source: sourceSize, target: targetSize)
    let cropOriginX = (scaledSize.width - targetSize.width) / 2
    let cropOriginY = (scaledSize.height - targetSize.height) / 2
    let cropRect = CGRect(x: cropOriginX, y: cropOriginY, width: targetSize.width, height: targetSize.height)

    image = UIImage(data: data)

    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1.0
    let renderer = UIGraphicsImageRenderer(size: scaledSize, format: format)
    var rendered = renderer.image { imageContext in
        image?.draw(in: CGRect(origin: .zero, size: scaledSize))
    }
    if let cgImage = rendered.cgImage, let cropped = cgImage.cropping(to: cropRect) {
        rendered = UIImage(cgImage: cropped)
    }
    return rendered
}

func scaleAndCropImageData(data:Data, targetSize:CGSize, rawImageSize:CGSize) -> UIImage? {

    var image:UIImage?
    var maxPixelSize:CGFloat = 0
    var cropRect:CGRect? = nil

    // Scaling up - use a resize and crop method
    if targetSize.width > rawImageSize.width || targetSize.height > rawImageSize.height {

        let scaledAndCroppedImage = resizeImageData(data: data, targetSize: targetSize, sourceSize: rawImageSize)
        image = scaledAndCroppedImage

    } else {

        // We can create a thumbnail

        if (targetSize.aspectRatio == rawImageSize.aspectRatio) || rawImageSize == .zero {

            maxPixelSize = max(targetSize.width, targetSize.height)

        } else {

            let newSize = scaleSourceToFit(source: CGRect(origin: .zero, size: rawImageSize), target: CGRect(origin: .zero, size: targetSize))

            maxPixelSize = max(newSize.width, newSize.height)

            cropRect = CGRect(x: (newSize.width - targetSize.width) / 2, y: (newSize.height - targetSize.height) / 2, width: targetSize.width, height: targetSize.height)
        }

        let options: [String:Any] = [kCGImageSourceCreateThumbnailFromImageAlways as String:true, kCGImageSourceThumbnailMaxPixelSize as String:maxPixelSize, kCGImageSourceCreateThumbnailWithTransform as String:true, kCGImageSourceShouldCacheImmediately as String:true]
        let sourceOptions:[String:Any] = [kCGImageSourceShouldCache as String:false]

        if let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary), let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            if let cropRect = cropRect, let croppedThumbnail = thumbnail.cropping(to: cropRect)  {
                    image = UIImage(cgImage: croppedThumbnail)
            } else {
                image = UIImage(cgImage:thumbnail)
            }
        }
    }

    if let img = image, img.size.width != targetSize.width && img.size.height != targetSize.height  {
        print("Sanity error: Final image size does not equal target size")
    }

    return image
}

typealias Decompressor = (UIImage) -> (UIImage)

let imageFetcherSimpleDecompressor: Decompressor = { image in
    let size = image.size
    UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
    image.draw(at: CGPoint.zero)
    let decompressed = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return decompressed ?? image
}


