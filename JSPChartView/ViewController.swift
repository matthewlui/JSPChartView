//
//  ViewController.swift
//  JSPChartView
//
//  Created by Matthew Lui on 1/2/2016.
//  Copyright © 2016 goldunderknees. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let data : [JSPBarValueRange] = [(23,55),(45,60),(25,145),(12,260),(534,668)]
    
    let data2 : [JSPBarValueRange] = [23,45,25,12,534,533,23,46,36,86,865,34,34].map(simpleBarValue)
    
    @IBOutlet var collectionView : UICollectionView!
    @IBOutlet var layout : JSPChartLayout!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        layout.dataSource = self
        collectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: JSPChartLayout.SupplementaryViewKindY, withReuseIdentifier: "Row")
        collectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: JSPChartLayout.SupplementaryViewKindX, withReuseIdentifier: "Col")
    }
    
}

extension ViewController : JSPChartLayoutDataSource {
    func valueRangeOfBar(atIndexPath indexPath: NSIndexPath) -> JSPBarValueRange {
        if indexPath.section == 0 { return data[indexPath.row] }
        return data2[indexPath.row]
    }
}

extension ViewController : UICollectionViewDelegate{
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let layout = JSPChartLayout()
        layout.vertical = false
        layout.dataSource = self
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.visibleCells().forEach { (cell) -> () in
            cell.layoutSubviews()
        }
    }
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == JSPChartLayout.SupplementaryViewKindY {
            let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Row", forIndexPath: indexPath)
            if indexPath.row % 2 == 0 {
                view.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.8, alpha: 1)
            }else{
                view.backgroundColor = UIColor.clearColor()
            }
            return view
        }
        
        let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Col", forIndexPath: indexPath)
        if indexPath.row % 2 == 0 {
            view.backgroundColor = UIColor(red: 0.8, green: 0.9, blue: 0.8, alpha: 1)
        }else{
            view.backgroundColor = UIColor.clearColor()
        }
        return view

    }
}

extension ViewController : UICollectionViewDataSource{
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return data.count }
        return data2.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        if cell.contentView.subviews.count == 0 {
            let label = UILabel(frame: cell.bounds)
            label.textColor = UIColor.redColor()

            cell.contentView.addSubview(label)
            cell.addConstraints([
                NSLayoutConstraint(item: label, attribute: .Top, relatedBy: .Equal, toItem: cell.contentView, attribute: .Top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: label, attribute: .Bottom, relatedBy: .Equal, toItem: cell.contentView, attribute: .Bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: label, attribute: .Trailing, relatedBy: .Equal, toItem: cell.contentView, attribute: .Trailing, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: label, attribute: .Leading, relatedBy: .Equal, toItem: cell.contentView, attribute: .Leading, multiplier: 1, constant: 0)])
            
        }
        if indexPath.section == 0 {
            cell.backgroundColor = UIColor.greenColor()
        }else{
            cell.backgroundColor = UIColor.yellowColor()
        }
        cell.contentView.subviews.forEach { (v) -> () in
            if let label = v as? UILabel {
                label.text = "\(indexPath.section).\(indexPath.row)"
            }
        }
        return cell
    }
    
}





