//
//  InterfaceController.swift
//  Amber-WatchApp Extension
//
//  Created by Rowan Willson on 5/9/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import WatchKit
import Foundation

/* Main Watch App interface class */
class InterfaceController: WKInterfaceController, AmberAPIDelegate {

    @IBOutlet weak var mainLabel: WKInterfaceLabel!
    @IBOutlet weak var circle: WKInterfaceGroup!
    @IBOutlet weak var renewablesLabel: WKInterfaceLabel!
    @IBOutlet weak var kWhLabel: WKInterfaceLabel!
    
    private var shouldPresentLoginViewOnAppear = false
    private var shouldUpdateDataOnAppear = false
    private var isSelfInitialisedAndVisible = false
    
    let watchSessionManager = WatchSessionManager.sharedManager 

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        AmberAPI.shared.delegate = self
        
        // Receive data from iPhone
        watchSessionManager.startSession()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        AmberAPI.shared.update { (result) in
            if result == .failWrongCredentials {
                // Handled below by delegate (not required in this completion handler)
            } else if result == .failOther {
                let okAction = WKAlertAction(title: "Ok", style: .default, handler: {})
                self.presentAlert(withTitle: "Error", message: "Connection error", preferredStyle: .alert, actions: [okAction])
            } else if result == .successFromNetwork {
                //Update Complication with new (non-cached) data
                let server = CLKComplicationServer.sharedInstance()
                server.activeComplications?.forEach(server.reloadTimeline)
            }
        }
    }
    
    override func didAppear() {
        isSelfInitialisedAndVisible = true
        
        if shouldPresentLoginViewOnAppear {
            shouldPresentLoginViewOnAppear = false
            presentLoginView()
        }
        
        if shouldUpdateDataOnAppear, let data = AmberAPI.shared.currentPriceData?.data  {
            shouldUpdateDataOnAppear = false
            updateInterface(withData: data)
        }
    }
    
    override func willDisappear() {
        isSelfInitialisedAndVisible = false
    }
    
    // MARK: - AmberAPI Delegate Methods
    
    // Update interface with new data now, or if interface not yet ready, on next didAppear()
    func updatePrices() {
        if isSelfInitialisedAndVisible, let data = AmberAPI.shared.currentPriceData?.data {
            updateInterface(withData: data) // Update now
        } else {
            shouldUpdateDataOnAppear = true
        }
    }
    
    // Schedule to show login screen on didAppear()
    func updateLoginDetails(requiresNewUserCredentials: Bool) {
        if isSelfInitialisedAndVisible && requiresNewUserCredentials {
            // Present now
            presentLoginView()
        } else {
            // Present after next didAppear()
            shouldPresentLoginViewOnAppear = requiresNewUserCredentials
        }
    }
    
    // MARK: View and Data Presentation
    
    private func presentLoginView() {
        self.presentController(withName: "Login", context: nil)
    }
    
    private func updateInterface(withData data : CurrentPriceData.PriceData) {
        let priceRounded = Int(data.currentPriceKWH)
        self.mainLabel.setText("\(priceRounded)¢")
        self.kWhLabel.setHidden(false)
        let renewableRounded = Int(data.currentRenewableInGrid)
        self.renewablesLabel.setText("\(renewableRounded)% Clean")
        self.circle.setBackgroundColor(Appearance.circleColour(from: data.currentPriceColor))
    }

}

