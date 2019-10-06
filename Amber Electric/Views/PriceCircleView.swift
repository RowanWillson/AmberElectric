//
//  PriceCircleView.swift
//  Amber Electric
//
//  Created by Rowan Willson on 1/9/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import UIKit

/* Create this class and assign a Price object to it.
 It will auto-layout adjust content to fit */
class PriceCircleView: UIView {
    
    // This is a current price
    var data : CurrentPriceData.PriceData? {
        didSet {
            if let data = data {
                let priceRounded = Int(data.currentPriceKWH)
                let renewableRounded = Int(data.currentRenewableInGrid)
                UIView.animate(withDuration: 0.1) {
                    self.marketingLabel.text = MarketingText.marketingText(from: data.currentPriceColor)
                    self.kWhLabel.text = "\(priceRounded)¢"
                    self.circle.backgroundColor = Appearance.circleColour(from: data.currentPriceColor)
                    self.unitLabel.alpha = 1.0
                    self.unitLabelAlt.alpha = 1.0
                    self.renewablePercentage.text = "\(renewableRounded)%"
                    self.renewableLabel.alpha = 1.0
                }
            }
        }
    }
    
    // Predicted Price
    var dataPredicted : CurrentPriceData.PriceData.Price? {
        didSet {
            if let data = dataPredicted {
                let priceRounded = Int(data.priceKWH)
                let renewableRounded = Int(data.renewableInGrid)
                UIView.animate(withDuration: 0.1) {
                    self.marketingLabel.text = nil
                    self.kWhLabel.text = "\(priceRounded)¢"
                    self.circle.backgroundColor = Appearance.circleColour(from: data.color)
                    self.unitLabel.alpha = 1.0
                    self.unitLabelAlt.alpha = 1.0
                    self.renewablePercentage.text = "\(renewableRounded)%"
                    self.renewableLabel.alpha = 1.0
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    private func setupView() {
        self.addSubview(circle)
        self.addSubview(marketingLabel)
        self.addSubview(kWhLabel)
        self.addSubview(unitLabel)
        self.addSubview(unitLabelAlt)
        self.addSubview(renewablePercentage)
        renewablePercentage.addSubview(renewableLabel)
        
        setupLayout()
    }
    
    var kWhWidthConstraint : NSLayoutConstraint?
    var kWhHeightConstraint : NSLayoutConstraint?
    
    private func setupLayout() {
        let tryToFillWidthConstraint = NSLayoutConstraint(item: circle, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
        tryToFillWidthConstraint.priority = .defaultHigh
        let tryToFillHeightConstraint = NSLayoutConstraint(item: circle, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
        tryToFillHeightConstraint.priority = .defaultHigh
        
        // We can increase size/height of the main price label as we scale up/down to fill more of the circle
        kWhWidthConstraint = NSLayoutConstraint(item: kWhLabel, attribute: .width, relatedBy: .equal, toItem: circle, attribute: .width, multiplier: 0.6, constant: 0.0)
        kWhHeightConstraint = NSLayoutConstraint(item: kWhLabel, attribute: .height, relatedBy: .equal, toItem: circle, attribute: .height, multiplier: 0.25, constant: 0.0)
        
        NSLayoutConstraint.activate([
            // Aspect ratio always square; fill and center.
            NSLayoutConstraint(item: circle, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: circle, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: circle, attribute: .width, relatedBy: .lessThanOrEqual, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: circle, attribute: .height, relatedBy: .lessThanOrEqual, toItem: self, attribute: .height, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: circle, attribute: .width, relatedBy: .equal, toItem: circle, attribute: .height, multiplier: 1.0, constant: 0.0),
            tryToFillWidthConstraint,
            tryToFillHeightConstraint,
            
            // Marketing label (e.g. "it's cheap and green...")
            NSLayoutConstraint(item: marketingLabel, attribute: .top, relatedBy: .equal, toItem: circle, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: marketingLabel, attribute: .height, relatedBy: .equal, toItem: circle, attribute: .height, multiplier: 0.35, constant: 0.0),
            NSLayoutConstraint(item: marketingLabel, attribute: .width, relatedBy: .equal, toItem: circle, attribute: .width, multiplier: 0.75, constant: 0.0),
            NSLayoutConstraint(item: marketingLabel, attribute: .centerX, relatedBy: .equal, toItem: circle, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            
            // kWhLabel position & size proportional to view width
            self.centerXAnchor.constraint(equalTo: kWhLabel.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: kWhLabel.centerYAnchor),
            kWhWidthConstraint!,
            kWhHeightConstraint!,
            
            // Unit Label fix to right of kWhLabel
            NSLayoutConstraint(item: unitLabel, attribute: .width, relatedBy: .equal, toItem: circle, attribute: .width, multiplier: 0.17, constant: 0.0),
            NSLayoutConstraint(item: unitLabel, attribute: .height, relatedBy: .equal, toItem: circle, attribute: .height, multiplier: 0.1, constant: 0.0),
            kWhLabel.rightAnchor.constraint(equalTo: unitLabel.leftAnchor),
            kWhLabel.bottomAnchor.constraint(equalTo: unitLabel.bottomAnchor),
            
            // Unit Label Alt (for small views) - below kWh view
            NSLayoutConstraint(item: unitLabelAlt, attribute: .width, relatedBy: .equal, toItem: circle, attribute: .width, multiplier: 0.3, constant: 0.0),
            NSLayoutConstraint(item: unitLabelAlt, attribute: .height, relatedBy: .equal, toItem: circle, attribute: .height, multiplier: 0.2, constant: 0.0),
            NSLayoutConstraint(item: unitLabelAlt, attribute: .top, relatedBy: .equal, toItem: kWhLabel, attribute: .bottom, multiplier: 1.0, constant: 1.0),
            NSLayoutConstraint(item: unitLabelAlt, attribute: .centerX, relatedBy: .equal, toItem: circle, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            
            // renewablePercentage position & size proportional to view width
            self.centerXAnchor.constraint(equalTo: renewablePercentage.centerXAnchor),
            NSLayoutConstraint(item: renewablePercentage, attribute: .top, relatedBy: .equal, toItem: kWhLabel, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: renewablePercentage, attribute: .bottom, relatedBy: .equal, toItem: circle, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: renewablePercentage, attribute: .width, relatedBy: .equal, toItem: circle, attribute: .width, multiplier: 0.35, constant: 0.0),
            
            // "Renewables" label
            NSLayoutConstraint(item: renewableLabel, attribute: .centerY, relatedBy: .equal, toItem: renewablePercentage, attribute: .centerY, multiplier: 1.6, constant: 0.0),
            NSLayoutConstraint(item: renewableLabel, attribute: .height, relatedBy: .equal, toItem: circle, attribute: .height, multiplier: 0.08, constant: 0.0),
            NSLayoutConstraint(item: renewableLabel, attribute: .width, relatedBy: .equal, toItem: circle, attribute: .width, multiplier: 0.3, constant: 0.0),
            NSLayoutConstraint(item: renewableLabel, attribute: .centerX, relatedBy: .equal, toItem: circle, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        ])
    }
    
    /* Show/hide certain labels depending on width */
    override func layoutSubviews() {
        let hidden = bounds.size.width < 220.0
        
        unitLabel.isHidden = hidden
        unitLabelAlt.isHidden = !hidden || bounds.size.width < 100.0
        marketingLabel.isHidden = hidden
        renewablePercentage.isHidden = hidden
        renewableLabel.isHidden = hidden
        
        //bump text size a little for small representations, e.g. Home Screen Widget
        if bounds.size.width < 130.0 {
            kWhHeightConstraint?.constant = 19
            kWhWidthConstraint?.constant = 10
        } else {
            kWhHeightConstraint?.constant = 0
            kWhWidthConstraint?.constant = 0
        }
    }
    
    // MARK: - Views
    
    private lazy var circle : Circle = {
        let circle = Circle()
        circle.backgroundColor = Appearance.amberGrayInactive
        circle.translatesAutoresizingMaskIntoConstraints = false
        return circle
    }()
    
    private lazy var marketingLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
        label.numberOfLines = 3
        label.textAlignment = NSTextAlignment.center
        label.baselineAdjustment = UIBaselineAdjustment.alignCenters //vertical alignment when shrink
        //label.font = UIFont.init(name: "WorkSans-Medium", size: 40.0) //start big. Auto-layout will shrink it
        label.font = UIFont.systemFont(ofSize: 40.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.3)  //DEBUG
        return label
    }()

    private lazy var kWhLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.05
        label.clipsToBounds = false
        label.textAlignment = NSTextAlignment.center
        label.baselineAdjustment = UIBaselineAdjustment.alignCenters //vertical alignment when shrink
        //label.font = UIFont.init(name: "WorkSans-Bold", size: 90.0) //start big. Auto-layout will shrink it
        label.font = UIFont.boldSystemFont(ofSize: 90.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = UIColor.black  //DEBUG
        return label
    }()
    
    private lazy var unitLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.alpha = 0.0
        label.text = "/kWh"
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
        label.baselineAdjustment = UIBaselineAdjustment.alignCenters //vertical alignment when shrink
        //label.font = UIFont.init(name: "WorkSans-Regular", size: 40.0) //start big. Auto-layout will shrink it
        label.font = UIFont.systemFont(ofSize: 40.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = UIColor.blue  //DEBUG
        return label
    }()
    
    private lazy var unitLabelAlt : UILabel = {  //for small view
        let label = UILabel()
        label.textColor = .white
        label.alpha = 0.0
        label.text = "/kWh"
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = NSTextAlignment.center
        label.minimumScaleFactor = 0.1
        label.baselineAdjustment = UIBaselineAdjustment.alignCenters //vertical alignment when shrink
        //label.font = UIFont.init(name: "WorkSans-Regular", size: 35.0) //start big. Auto-layout will shrink it
        label.font = UIFont.systemFont(ofSize: 40.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = UIColor.blue  //DEBUG
        return label
    }()
    
    private lazy var renewablePercentage : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
        label.textAlignment = NSTextAlignment.center
        label.baselineAdjustment = UIBaselineAdjustment.alignCenters //vertical alignment when shrink
        //label.font = UIFont.init(name: "WorkSans-Bold", size: 90.0) //start big. Auto-layout will shrink it
        label.font = UIFont.boldSystemFont(ofSize: 90.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.3)  //DEBUG
        return label
    }()
    
    private lazy var renewableLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.text = "Renewables"
        label.alpha = 0.0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.05
        label.textAlignment = NSTextAlignment.center
        label.baselineAdjustment = UIBaselineAdjustment.alignCenters //vertical alignment when shrink
        //label.font = UIFont.init(name: "WorkSans-Medium", size: 70.0) //start big. Auto-layout will shrink it
        label.font = UIFont.systemFont(ofSize: 70.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = UIColor.red  //DEBUG
        return label
    }()
    
}

fileprivate class Circle: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
}
