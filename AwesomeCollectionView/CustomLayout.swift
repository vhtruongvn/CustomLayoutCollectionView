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
    
    var longPress: UILongPressGestureRecognizer!
    var originalIndexPath: IndexPath?
    var draggingIndexPath: IndexPath?
    var draggingView: UIView?
    var dragOffset = CGPoint.zero
    
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
                    if item == 0 {
                        frame.size.width *= 2
                        frame.size.height *= 2
                    } else if item == 1 {
                        frame.origin.x *= 2
                    } else if item == 2 {
                        frame.origin.y = height
                    } else {
                        frame.origin.y += height
                        
                        let row = (item / numberOfColumns) + 1
                        if row % 2 == 0 {
                            // reverse order
                            frame.origin.x = xOffset[(numberOfColumns - 1) - column]
                        } else {
                            // keep items in this order
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
        
        installGestureRecognizer()
    }
    
    override var collectionViewContentSize : CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        // Loop through the cache and look for items in the rect
        for attributes in cache {
            if attributes.frame.intersects(rect ) {
                layoutAttributes.append(attributes)
            }
        }
        
        return layoutAttributes
    }
    
    func installGestureRecognizer() {
        if longPress == nil {
            longPress = UILongPressGestureRecognizer(target: self, action: #selector(CustomLayout.handleLongPress(_:)))
            longPress.minimumPressDuration = 0.2
            collectionView?.addGestureRecognizer(longPress)
        }
    }
    
    func handleLongPress(_ longPress: UILongPressGestureRecognizer) {
        let location = longPress.location(in: collectionView!)
        switch longPress.state {
        case .began: startDragAtLocation(location: location)
        case .changed: updateDragAtLocation(location: location)
        case .ended: endDragAtLocation(location: location)
        default:
            break
        }
    }
    
    func startDragAtLocation(location: CGPoint) {
        guard let cv = collectionView else { return }
        guard let indexPath = cv.indexPathForItem(at: location) else { return }
        guard cv.dataSource?.collectionView?(cv, canMoveItemAt: indexPath) == true else { return }
        guard let cell = cv.cellForItem(at: indexPath) else { return }
        
        originalIndexPath = indexPath
        draggingIndexPath = indexPath
        draggingView = cell.snapshotView(afterScreenUpdates: true)
        draggingView!.frame = cell.frame
        cv.addSubview(draggingView!)
        
        dragOffset = CGPoint(x: draggingView!.center.x - location.x, y: draggingView!.center.y - location.y)
        
        draggingView?.layer.shadowPath = UIBezierPath(rect: draggingView!.bounds).cgPath
        draggingView?.layer.shadowColor = UIColor.black.cgColor
        draggingView?.layer.shadowOpacity = 0.8
        draggingView?.layer.shadowRadius = 10
        
        invalidateLayout()
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [], animations: {
            self.draggingView?.alpha = 0.95
            self.draggingView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: nil)
    }
    
    func updateDragAtLocation(location: CGPoint) {
        guard let view = draggingView else { return }
        guard let cv = collectionView else { return }
        
        view.center = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
        
        if let newIndexPath = cv.indexPathForItem(at: location) {
            if newIndexPath.row == cv.numberOfItems(inSection: newIndexPath.section) - 1 { // Add button is not movable
                return
            }
            cv.moveItem(at: draggingIndexPath!, to: newIndexPath)
            draggingIndexPath = newIndexPath
        }
    }
    
    func endDragAtLocation(location: CGPoint) {
        guard let dragView = draggingView else { return }
        guard let indexPath = draggingIndexPath else { return }
        guard let cv = collectionView else { return }
        guard let datasource = cv.dataSource else { return }
        
        let targetCenter = datasource.collectionView(cv, cellForItemAt: indexPath).center
        
        let shadowFade = CABasicAnimation(keyPath: "shadowOpacity")
        shadowFade.fromValue = 0.8
        shadowFade.toValue = 0
        shadowFade.duration = 0.4
        dragView.layer.add(shadowFade, forKey: "shadowFade")
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [], animations: {
            dragView.center = targetCenter
            dragView.transform = CGAffineTransform.identity
        }) { (completed) in
            if !(indexPath as NSIndexPath).isEqual(self.originalIndexPath!) {
                datasource.collectionView!(cv, moveItemAt: self.originalIndexPath!, to: indexPath)
            }
            
            dragView.removeFromSuperview()
            self.draggingIndexPath = nil
            self.draggingView = nil
            self.invalidateLayout()
        }
    }
    
}
