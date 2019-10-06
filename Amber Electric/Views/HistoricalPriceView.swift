//
//  HistoricalPriceView.swift
//  Amber Electric
//
//  Created by Rowan Willson on 4/9/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

/* Display historical data, e.g. this weeks usage.
 Note: This view requires implementing in draw(:) */
class HistoricalPriceView : UIView {
    
    var historicalPriceData : [CurrentPriceData.PriceData.Price]? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    //initWithCode to init view from xib or storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        self.contentMode = .redraw  //redraw entire graph when bounds change
        self.clearsContextBeforeDrawing = true
        
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        //white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)
        
        if let data = historicalPriceData {
            
            //find min/max
            var minPrice = Double.greatestFiniteMagnitude
            var maxPrice = -Double.greatestFiniteMagnitude
            
            for price in data {
                minPrice = min(price.priceKWH, minPrice)
                maxPrice = max(price.priceKWH, maxPrice)
            }
            
            context.setLineWidth(2.0)
            
            // TODO: Draw historicalPriceData graph as required...
            
        } else {
            //Draw error message text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes: [NSAttributedString.Key : Any] = [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.systemFont(ofSize: 12.0),
                .foregroundColor: UIColor.black
            ]
            let attributedString = NSAttributedString(string: "No data", attributes: attributes)
            attributedString.draw(at: CGPoint(x: rect.size.width/2-20, y: rect.size.height/2))
        }
    }
    
    
}
