//
//  PriceDeconstructedView.swift
//  Amber Electric
//
//  Created by Rowan Willson on 3/9/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import UIKit

/* This view is used in predicted prices scrollView */
class PriceDeconstructedView: UIView {
    
    var dataPredicted : CurrentPriceData.PriceData.Price? {
        didSet {
            if let data = dataPredicted {
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone.current
                dateFormatter.dateFormat = "h:mma" // 10:30AM
                let timeString = dateFormatter.string(from: data.period)
                
                let priceRounded = Int(data.priceKWH)
                let renewableRounded = Int(data.renewableInGrid)
                UIView.animate(withDuration: 0.1) {
                    self.timeLabel.text = timeString
                    self.circleView.backgroundColor = Appearance.circleColour(from: data.color)
                    self.priceLabel.text = "\(priceRounded)¢"
                    self.renewablesLabel.text = "\(renewableRounded)%"
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        
        self.addSubview(vStack)
        vStack.addArrangedSubview(timeLabel)
        vStack.addArrangedSubview(circleView)
        vStack.addArrangedSubview(priceLabel)
        vStack.addArrangedSubview(renewablesLabel)
        
        // auto-layout
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: vStack.topAnchor),
            self.bottomAnchor.constraint(equalTo: vStack.bottomAnchor),
            self.leftAnchor.constraint(equalTo: vStack.leftAnchor),
            self.rightAnchor.constraint(equalTo: vStack.rightAnchor),
            
            NSLayoutConstraint(item: circleView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: self.circleSize),
            NSLayoutConstraint(item: circleView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: self.circleSize)
        ])
    }
    
    // MARK: - Views
    
    private lazy var vStack : UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        stack.spacing = UIStackView.spacingUseSystem
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var timeLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.systemFont(ofSize: 16.0)
        if #available(iOS 13.0, *) {
            label.textColor = .label
        }
        return label
    }()
    
    // Fixed size circle
    private let circleSize : CGFloat = 50.0
    private lazy var circleView : UIView = {
        let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: circleSize, height: circleSize))
        view.layer.cornerRadius = circleSize / 2
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.backgroundColor = Appearance.amberGrayInactive
        return view
    }()
    
    private lazy var priceLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        if #available(iOS 13.0, *) {
            label.textColor = .label
        }
        label.clipsToBounds = false
        return label
    }()
    
    private lazy var renewablesLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        }
        label.clipsToBounds = false
        return label
    }()
    
}
