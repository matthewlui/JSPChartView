//
//  JSPChartLayout.swift
//  JSPChartView
//
//  Created by Matthew Lui on 2/2/2016.
//  Copyright © 2016 goldunderknees. All rights reserved.
//

import UIKit


typealias JSPBarValueRange = (Double,Double)

func barValueOfRange(range:JSPBarValueRange) -> Double{
    return range.1-range.0
}

func barRangeByAppendingValue(value:Double,toBaseRange baseRange:JSPBarValueRange) -> JSPBarValueRange {
    return (baseRange.1,baseRange.1+value)
}

/// helper method for map a [Double] into [JSPBarValueRange]. Each JSPBarValueRange tuple is (0,VALUE)
///
/// ---
///
/// Use:
///
///     SOMEDOUBLEARRAY.map(simpleBarValue)
func simpleBarValue(value:Double)->JSPBarValueRange{
    return (0,value)
}

func /(lhs:JSPBarValueRange,rhs:JSPBarValueRange) -> JSPBarValueRange {
    return (lhs.0 / (abs(rhs.0)+abs(rhs.1)), lhs.1 / (abs(rhs.0)+abs(rhs.1)))
}

func *(lhs:JSPBarValueRange,rhs:CGFloat) -> (CGFloat,CGFloat) {
    return ( CGFloat(lhs.0) * rhs, CGFloat(lhs.1) * rhs )
}

protocol JSPChartLayoutDataSource {
    func valueRangeOfBar(atIndexPath indexPath:NSIndexPath) -> JSPBarValueRange
}

class JSPChartLayout : UICollectionViewLayout {
    
    static let SupplementaryViewKindX = "SupplementaryViewKindX"
    static let SupplementaryViewKindY = "SupplementaryViewKindY"
    
    var vertical    = true
    var barWidth    : CGFloat = 40
    var barGap      : CGFloat = 40
    var dataRange   : JSPBarValueRange = (0,100)
    var dataSource  : JSPChartLayoutDataSource?
    var cacheSize   = CGSizeZero
    var insect      = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
    
    override func collectionViewContentSize() -> CGSize {
        guard let collectionView = collectionView else { return CGSizeZero }
        let sections = collectionView.numberOfSections()
        var maxCell = 0
        for section in 0..<sections {
            let cells = collectionView.numberOfItemsInSection(section)
            maxCell = maxCell > cells ? maxCell : cells
        }
        let length = (barWidth+barGap) * CGFloat(maxCell)
        if vertical {
            cacheSize = CGSize(width: length + insect.left + insect.right,
                height: collectionView.bounds.height + insect.top + insect.bottom)
            return cacheSize
        }else{
            cacheSize = CGSize(width: collectionView.bounds.width + insect.left + insect.right, height: length + insect.top + insect.bottom)
            return cacheSize
        }
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var beginIndex :Int , endIndex :Int
        if vertical {
            beginIndex = max(0,Int(rect.minX / (barWidth + barGap)))
            endIndex = max(0,Int(rect.maxX / (barWidth + barGap)))
        }else{
            beginIndex = max(0,Int(rect.minY / (barWidth + barGap)))
            endIndex = max(0,Int(rect.maxY / (barWidth + barGap)))
        }
        guard let collectionView = collectionView else { return nil }
        
        let indexes = 0.stride(to: collectionView.numberOfSections(), by: 1).map { (section) -> [NSIndexPath] in
            return beginIndex.stride(to: collectionView.numberOfItemsInSection(section), by: 1).map({ (row) -> NSIndexPath? in
                if row > endIndex{
                    return nil
                }
                return NSIndexPath(forRow: row, inSection: section)
            }).flatMap(){return $0}
        }
        
        if let dataSource = dataSource {
            dataRange = indexes.reduce((0,0), combine: { (pre, cur) -> JSPBarValueRange in
                cur.reduce(pre, combine: { (r, indexPath) -> JSPBarValueRange in
                    let rangAtIndex = dataSource.valueRangeOfBar(atIndexPath: indexPath)
                    return (min(r.0,rangAtIndex.0),max(r.1,rangAtIndex.1))
                })
            })
        }
        
        let attrs = indexes.map({ indexPaths -> [UICollectionViewLayoutAttributes] in
            return indexPaths.map({ indexPath -> UICollectionViewLayoutAttributes? in
                return self.layoutAttributesForItemAtIndexPath(indexPath)
            }).flatMap(){$0}
        })
        
        let supplementaryRowAttrs = 0.stride(to: 11, by: 1).map { (index) -> UICollectionViewLayoutAttributes? in
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            return layoutAttributesForSupplementaryViewOfKind(JSPChartLayout.SupplementaryViewKindY, atIndexPath: indexPath)
            }.flatMap({$0})
        let supplementaryColAttrs = beginIndex.stride(to: endIndex, by: 1).map { (index) -> UICollectionViewLayoutAttributes? in
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            return layoutAttributesForSupplementaryViewOfKind(JSPChartLayout.SupplementaryViewKindX, atIndexPath: indexPath)
            }.flatMap({$0})
        return attrs.reduce([], combine: { (pre, cur) -> [UICollectionViewLayoutAttributes] in
            return pre + cur
        }) + supplementaryRowAttrs + supplementaryColAttrs
        
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        var attr = super.layoutAttributesForItemAtIndexPath(indexPath)
        if attr == nil {
            attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        }
        attr?.frame = frameForLayoutAttributesInCurrenContextAtIndexPath(indexPath)
        return attr
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        var attr = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
        if attr == nil {
            attr = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
        }
        attr?.frame = frameForLayoutAttributeOfSupplementaryViewAtIndexPath(kind: elementKind, indexPath: indexPath)
        attr?.zIndex = -1
        return attr
    }
    
    func frameForLayoutAttributesInCurrenContextAtIndexPath(indexPath:NSIndexPath) -> CGRect{
        guard let dataSource = dataSource else { return CGRectZero }
        let beginingPoint = (barWidth + barGap) * CGFloat(indexPath.row)
        let range = dataSource.valueRangeOfBar(atIndexPath: indexPath) / dataRange
        
        if vertical {
            let representLocation = range * cacheSize.height
            let length = representLocation.1 - representLocation.0
            return CGRect(x: beginingPoint + insect.left, y: cacheSize.height - representLocation.0 - length - insect.bottom, width: barWidth, height: length)
        }else{
            let representLocation = range * cacheSize.width
            let length = representLocation.1 - representLocation.0
            return CGRect(x: cacheSize.width - representLocation.0 - length + insect.left , y: beginingPoint - insect.bottom, width: length, height: barWidth)
        }
    }
    
    func frameForLayoutAttributeOfSupplementaryViewAtIndexPath(kind kind:String,indexPath:NSIndexPath) -> CGRect{
        
        if vertical {
            return frameForLayoutAttributeOfSupplementaryViewVerticallyAtIndexPath(kind: kind, indexPath: indexPath)
        }else{
            return frameForLayoutAttributeOfSupplementaryViewHorizontallyAtIndexPath(kind: kind, indexPath: indexPath)
        }
        
    }
    
    func frameForLayoutAttributeOfSupplementaryViewVerticallyAtIndexPath(kind kind:String,indexPath:NSIndexPath) -> CGRect{
        guard let dataSource = dataSource else { return CGRectZero }
        let beginingPoint :CGFloat,length :CGFloat
        if kind == JSPChartLayout.SupplementaryViewKindX {
            length = cacheSize.height / 10
            beginingPoint = (barWidth + barGap) * (CGFloat(indexPath.row) - 0.25)
            return CGRect(x: beginingPoint + insect.left, y: 0, width: barWidth + barGap, height: cacheSize.height)
        }
        if kind == JSPChartLayout.SupplementaryViewKindY {
            length = cacheSize.height / 10
            beginingPoint = cacheSize.height - CGFloat(indexPath.row) * length
            return CGRect(x: 0, y: beginingPoint, width: cacheSize.width, height: length)
        }
        return CGRectZero
    }
    
    func frameForLayoutAttributeOfSupplementaryViewHorizontallyAtIndexPath(kind kind:String,indexPath:NSIndexPath) -> CGRect{
        guard let dataSource = dataSource else { return CGRectZero }
        let beginingPoint :CGFloat,length :CGFloat
        if kind == JSPChartLayout.SupplementaryViewKindX {
            
        }
        if kind == JSPChartLayout.SupplementaryViewKindY {
            
        }
        return CGRectZero
    }
    
}
