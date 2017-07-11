//
//  CustomLayout.swift
//  AwesomeCollectionView
//
//  Created by Truong Vo on 11/7/17.
//  Copyright © 2017 RayMob. All rights reserved.
//

import UIKit

class CustomLayoutAttributes: UICollectionViewLayoutAttributes {
    
    // Custom attribute
    var photoWidth: CGFloat = 0.0
    var photoHeight: CGFloat = 0.0
    
    // Override copyWithZone to conform to NSCopying protocol
    override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! CustomLayoutAttributes
        copy.photoWidth = photoWidth
        copy.photoHeight = photoHeight
        return copy
    }
    
    // Override isEqual
    override func isEqual(_ object: Any?) -> Bool {
        if let attributtes = object as? CustomLayoutAttributes {
            if (attributtes.photoWidth == photoWidth && attributtes.photoHeight == photoHeight) {
                return super.isEqual(object)
            }
        }
        return false
    }
}

class CustomLayout: UICollectionViewLayout {
    
    var cellPadding: CGFloat = 6.0
    
    // Array to keep a cache of attributes.
    fileprivate var cache = [CustomLayoutAttributes]()
    
    // Content height and size
    fileprivate var contentHeight:CGFloat  = 0.0
    fileprivate var contentWidth: CGFloat {
        let insets = collectionView!.contentInset
        return collectionView!.bounds.width - (insets.left + insets.right)
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        cache.removeAll()
    }
    
    override class var layoutAttributesClass : AnyClass {
        return CustomLayoutAttributes.self
    }
    
    override func prepare() {
        // Only calculate once
        if cache.isEmpty {
            // Pre-Calculates the X Offset for every column and adds an array to increment the currently max Y Offset for each column
            let columnWidth = contentWidth / CGFloat(numberOfColumns)
            var xOffset = [CGFloat]()
            for column in 0 ..< numberOfColumns {
                xOffset.append(CGFloat(column) * columnWidth )
            }
            var column = 0
            var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
            
            // Iterates through the list of items in each section
            for section in 0 ..< collectionView!.numberOfSections {
                for item in 0 ..< collectionView!.numberOfItems(inSection: section) {
                    let indexPath = IndexPath(item: item, section: section)
                    
                    let width = columnWidth
                    let height = width
                    var frame = CGRect(x: xOffset[column], y: yOffset[column], width: width, height: height)
                    if section == 0 {
                        if item == 0 {
                            frame.size.width *= 2
                            frame.size.height *= 2
                        } else if item == 1 {
                            frame.origin.x *= 2
                        } else if item == 2 {
                            frame.origin.y = height
                        }
                    } else {
                        frame.origin.y += height
                        
                        let row = (item / numberOfColumns) + 1
                        if row % 2 == 0 {
                            // keep items in this order
                        } else {
                            // reverse order
                            frame.origin.x = xOffset[(numberOfColumns - 1) - column]
                        }
                    }
                    let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
                    
                    // Creates an UICollectionViewLayoutItem with the frame and add it to the cache
                    let attributes = CustomLayoutAttributes(forCellWith: indexPath)
                    attributes.photoWidth = width
                    attributes.photoHeight = height
                    attributes.frame = insetFrame
                    cache.append(attributes)
                    
                    // Updates the collection view content height
                    contentHeight = max(contentHeight, frame.maxY)
                    yOffset[column] = yOffset[column] + height
                    
                    column = column >= (numberOfColumns - 1) ? 0 : column + 1
                }
            }
        }
    }
    
    override var collectionViewContentSize : CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        // Loop through the cache and look for items in the rect
        for attributes  in cache {
            if attributes.frame.intersects(rect ) {
                layoutAttributes.append(attributes)
            }
        }
        
        return layoutAttributes
    }
    
}
