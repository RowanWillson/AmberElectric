//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by Rowan Willson on 31/8/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import UIKit
import NotificationCenter

/* Home Screen widget - aka TodayExtension.
 Displays current price circle plus the next few predicted prices */
class AmberWidgetViewController: UIViewController, NCWidgetProviding {
    
    private let numberOfPredictedCircles = 3
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add views
        view.addSubview(hStack) //initially hidden.
        view.addSubview(loadingTextLabel)
        
        let vStack = createGenericVStack(withViews: mainPriceLabel,mainPriceCircle)
        hStack.addArrangedSubview(vStack)
        hStack.addArrangedSubview(predictedHStack)
        
        for i in 0..<numberOfPredictedCircles {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 30))
            let vStack2 = createGenericVStack(withViews: paddingView, predictedPriceLabels[i], predictedPriceCircles[i])
            predictedHStack.addArrangedSubview(vStack2)
        }
        
        // Auto-layout hStack inside widget
        NSLayoutConstraint.activate([
            self.view.leftAnchor.constraint(equalTo: hStack.leftAnchor),
            self.view.rightAnchor.constraint(equalTo: hStack.rightAnchor),
            self.view.topAnchor.constraint(equalTo: hStack.topAnchor),
            self.view.bottomAnchor.constraint(equalTo: hStack.bottomAnchor),
            
            self.view.leftAnchor.constraint(equalTo: loadingTextLabel.leftAnchor),
            self.view.rightAnchor.constraint(equalTo: loadingTextLabel.rightAnchor),
            self.view.topAnchor.constraint(equalTo: loadingTextLabel.topAnchor),
            self.view.bottomAnchor.constraint(equalTo: loadingTextLabel.bottomAnchor)
        ])
        
        // Gesture recogniser (anywhere) opens host (main) iPhone app
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openHostApp))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func openHostApp() {
        if let url = URL(string: "amberelectric:") {
            self.extensionContext?.open(url, completionHandler: nil)
        }
    }
    
    /* Helper function for creating regularly used stack views full of view's */
    private func createGenericVStack(withViews views : UIView...) -> UIStackView {
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.translatesAutoresizingMaskIntoConstraints = false
        for view in views {
            vStack.addArrangedSubview(view)
        }
        return vStack
    }
    
    /* System regularly calls this function (normally on view appearing) to update interface */
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        AmberAPI.shared.update { (result) in
            if result == .successFromNetwork {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.updateUI()
                    }, completion: { (_) in
                        completionHandler(NCUpdateResult.newData)
                    })
                }
            } else if result == .successFromCache {
                // non-animated to avoid visual glitches
                // Already on main thread
                self.updateUI()
                completionHandler(NCUpdateResult.newData)  //always return newData (not noData) because main iOS app could have updated the data.
            } else {
                completionHandler(NCUpdateResult.failed)
            }
        }
    }
    
    private func updateUI() {
        hStack.alpha = 1.0
        loadingTextLabel.alpha = 0.0
        
        mainPriceCircle.data = AmberAPI.shared.currentPriceData?.data
        mainPriceLabel.text = "NOW"
        
        if AmberAPI.shared.currentPriceData?.data.forecastPrices.count ?? 0 > numberOfPredictedCircles {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.dateFormat = "h:mma" // e.g. 10:30AM
            for i in 0..<numberOfPredictedCircles {
                predictedPriceCircles[i].dataPredicted = AmberAPI.shared.currentPriceData?.data.forecastPrices[i]
                let currentTime = dateFormatter.string(from: AmberAPI.shared.currentPriceData?.data.forecastPrices[i].period ?? Date())
                predictedPriceLabels[i].text = currentTime
            }
        }
    }
    
    // MARK: - Views
    
    private lazy var hStack : UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 4, trailing: 8)
        stack.spacing = UIStackView.spacingUseSystem
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alpha = 0.0
        return stack
    }()
    
    private lazy var predictedHStack : UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 4, trailing: 14)
        stack.alignment = UIStackView.Alignment.bottom
        stack.spacing = UIStackView.spacingUseSystem
        stack.distribution = UIStackView.Distribution.fillEqually
        return stack
    }()
    
    private lazy var mainPriceCircle : PriceCircleView = {
        let priceCircle = PriceCircleView()
        priceCircle.translatesAutoresizingMaskIntoConstraints = false
        return priceCircle
    }()
    
    private lazy var mainPriceLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    private lazy var predictedPriceCircles : [PriceCircleView] = {
        var predictedPriceViews : [PriceCircleView] = []
        for _ in 0..<numberOfPredictedCircles {
            let priceCircle = PriceCircleView()
            priceCircle.translatesAutoresizingMaskIntoConstraints = false
            predictedPriceViews.append(priceCircle)
        }
        return predictedPriceViews
    }()
    
    private lazy var predictedPriceLabels : [UILabel] = {
        var labels : [UILabel] = []
        for _ in 0..<numberOfPredictedCircles {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14.0)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = NSTextAlignment.center
            labels.append(label)
        }
        return labels
    }()
    
    private lazy var loadingTextLabel : UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textAlignment = NSTextAlignment.center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
}
