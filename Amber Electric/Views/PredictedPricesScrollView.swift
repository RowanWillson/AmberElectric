//
//  PredictedPricesScrollView.swift
//  Amber Electric
//
//  Created by Rowan Willson on 3/9/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import UIKit

/* Horizontal scrollView full of PriceDeconstructedView's to display predicted prices */
class PredictedPricesScrollView: UIScrollView {
    
    var forecastPriceData : [CurrentPriceData.PriceData.Price]? {
        didSet {
            if let prices = forecastPriceData {
                // Remove old ones
                for view in hStackContentView.arrangedSubviews {
                    hStackContentView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }
                // Add new ones
                for price in prices {
                    let forecastCircleView = PriceDeconstructedView()
                    hStackContentView.addArrangedSubview(forecastCircleView)
                    forecastCircleView.dataPredicted = price
                }
            }
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
        
        self.addSubview(hStackContentView)
        
        // auto-layout - this becomes the scrollView's content
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: hStackContentView.topAnchor),
            self.bottomAnchor.constraint(equalTo: hStackContentView.bottomAnchor),
            self.leftAnchor.constraint(equalTo: hStackContentView.leftAnchor),
            self.rightAnchor.constraint(equalTo: hStackContentView.rightAnchor)
        ])
        
        // configure scrollView
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = true
        self.alwaysBounceVertical = false
        self.isDirectionalLockEnabled = true
    }
    
    // MARK: - Views
    
    private lazy var hStackContentView : UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        stack.spacing = UIStackView.spacingUseSystem
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

}
