//
//  ViewController.swift
//  Amber Electric
//
//  Created by Rowan Willson on 31/8/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, AmberAPIDelegate {
    
    // MARK - View Management
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        AmberAPI.shared.delegate = self
        
        // Add subviews
        view.addSubview(nameLabel)
//        view.addSubview(logoutButton)
        view.addSubview(predictedPricesTitleLabel)
        view.addSubview(priceCircle)
        view.addSubview(predictedPricesScrollView)
        view.addSubview(scrollLeftTapAreaView)
        
        // DEBUG
//        view.addSubview(historicalGraph)
//        NSLayoutConstraint.activate([
//            historicalGraph.topAnchor.constraint(equalTo: view.topAnchor),
//            historicalGraph.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            historicalGraph.leftAnchor.constraint(equalTo: view.leftAnchor),
//            historicalGraph.rightAnchor.constraint(equalTo: view.rightAnchor)
//        ])

        
        // Auto-layout for subviews. This can be done with less boilerplate and better readability using SnapKit but I've gone for a project with no external dependencies (no Podfile) for easier distribution & setup by third parties, or for non-iOS developers to more easily build and test. Feel free to change for future UI modification when adding new features :p
        NSLayoutConstraint.activate([
            // Name Label (top left)
            NSLayoutConstraint(item: nameLabel, attribute: .top, relatedBy: .equal, toItem: view, attribute: .topMargin, multiplier: 1.0, constant: 8.0),
            NSLayoutConstraint(item: nameLabel, attribute: .left, relatedBy: .equal, toItem: view, attribute: .leftMargin, multiplier: 1.0, constant: 0.0),
            
            // Logout button (top right)
//            NSLayoutConstraint(item: logoutButton, attribute: .top, relatedBy: .equal, toItem: view, attribute: .topMargin, multiplier: 1.0, constant: 4.0),
//            NSLayoutConstraint(item: logoutButton, attribute: .right, relatedBy: .equal, toItem: view, attribute: .rightMargin, multiplier: 1.0, constant: 8.0),
            
            // Price Circle
            NSLayoutConstraint(item: priceCircle, attribute: .top, relatedBy: .equal, toItem: view, attribute: .topMargin, multiplier: 1.0, constant: 8.0),
            NSLayoutConstraint(item: priceCircle, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: priceCircle, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.95, constant: 0.0),
            NSLayoutConstraint(item: priceCircle, attribute: .bottom, relatedBy: .equal, toItem: predictedPricesScrollView, attribute: .top, multiplier: 1.0, constant: 8.0),
            
            // ScrollView on the bottom. Fixed height.
            NSLayoutConstraint(item: predictedPricesScrollView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottomMargin, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: predictedPricesScrollView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: predictedPricesScrollView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: predictedPricesScrollView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 170.0),
            
            // Predicted Prices label (on top of scrollView to the left)
            NSLayoutConstraint(item: predictedPricesTitleLabel, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottomMargin, multiplier: 1.0, constant: -170.0),
            NSLayoutConstraint(item: predictedPricesTitleLabel, attribute: .left, relatedBy: .equal, toItem: view, attribute: .leftMargin, multiplier: 1.0, constant: 0.0),
            
            // Scroll left tap area (to the left of scrollView)
            NSLayoutConstraint(item: scrollLeftTapAreaView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: scrollLeftTapAreaView, attribute: .top, relatedBy: .equal, toItem: predictedPricesScrollView, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: scrollLeftTapAreaView, attribute: .bottom, relatedBy: .equal, toItem: predictedPricesScrollView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: scrollLeftTapAreaView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 25.0)

        ])
    }
    
    // Remove this variable once implemented a logout button or action sheet.
    #if DEBUG
    private var forceDisplayLoginOnStartup = false  //DEBUG OPTION - Set to 'true' to force display login screen for demo purposes.
    #else
    private var forceDisplayLoginOnStartup = false  //RELEASE BUILDS - Always leave as 'false'
    #endif
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let defaults = UserDefaults.shared
        
        // Show login screen if no user credentials saved.
        if forceDisplayLoginOnStartup || defaults.string(forKey: DefaultsKeys.usernameKey) == nil
            || defaults.string(forKey: DefaultsKeys.passwordKey) == nil {
            forceDisplayLoginOnStartup = false
            presentLoginScreen(animated: false, withErrorText: nil)
        }
    }
    
    /* Grab latest prices from API */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AmberAPI.shared.update(completionHandler: nil)
    }
    
    // Flash scroll bar indicator after rotate so the user can better see where they are in the predicted prices scrollView
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        predictedPricesScrollView.flashScrollIndicators()
    }
    
    @objc private func presentLoginScreen() {
        presentLoginScreen(animated: true, withErrorText: nil)
    }
    
    private func presentLoginScreen(animated : Bool, withErrorText text : String?) {
        let loginViewController = LoginViewController()
        loginViewController.errorText = text
        loginViewController.modalPresentationStyle = .formSheet
        self.present(loginViewController, animated: animated, completion: nil)
    }
    
    // MARK: - API Delegate
    
    func updateLoginDetails(requiresNewUserCredentials : Bool) {
        if requiresNewUserCredentials {
            presentLoginScreen(animated: true, withErrorText: "Auth Failure: please enter valid user credentials.")
        } else {
            // Update UI with login info
            self.nameLabel.text = AmberAPI.shared.authData?.data.name
            self.emailLabel.text = AmberAPI.shared.authData?.data.email
            self.postcodeLabel.text = AmberAPI.shared.authData?.data.postcode
            
            // Update Watch Extension if it has not yet been sent login details
            LoginViewController.sendLoginDetailsToWatch(force: true)
        }
    }
    
    func updatePrices() {
        if let latestPriceData = AmberAPI.shared.currentPriceData?.data {
            priceCircle.data = latestPriceData
            predictedPricesScrollView.forecastPriceData = latestPriceData.forecastPrices
        }
    }
    
    /*
    override func updateHistoricalUsage() {
        //TODO: Implement
    } */

    @objc func scrollLeft() {
        predictedPricesScrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
    }
    
    // MARK: - Views
    
    private lazy var nameLabel : UILabel = {
        let label = UILabel()
        if #available(iOS 13.0, *) {
            label.textColor = .label
        } else {
            label.textColor = .black
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emailLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var postcodeLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var priceLabel : UILabel = {
        let label = UILabel()
        label.text = "Price"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var priceCircle : PriceCircleView = {
        let priceCircle = PriceCircleView()
        priceCircle.translatesAutoresizingMaskIntoConstraints = false
        return priceCircle
    }()
    
    private lazy var predictedPricesTitleLabel : UILabel = {
        let label = UILabel()
        label.text = "Forecast Prices"
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 22.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var predictedPricesScrollView : PredictedPricesScrollView = {
        let scrollView = PredictedPricesScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var scrollLeftTapAreaView : UIView = {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(scrollLeft))
        view.addGestureRecognizer(tapGesture)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    
//    private lazy var logoutButton : UIButton = {
//        let button = UIButton()
//        button.setTitle("Logout", for: .normal)
//        button.setTitleColor(Appearance.amberBlue, for: .normal)
//        button.addTarget(self, action: #selector(presentLoginScreen as () -> Void), for: .touchUpInside)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
    
//    private lazy var historicalGraph : HistoricalPriceView = {
//        let graph = HistoricalPriceView()
//        graph.translatesAutoresizingMaskIntoConstraints = false
//
//        return graph
//    }()
    
}

