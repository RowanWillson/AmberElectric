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
                // Display error to user. Keep messages short to fit on Watch.
                let okAction = WKAlertAction(title: "Ok", style: .default, handler: {})
                self.presentAlert(withTitle: "Error", message: "Auth error. Open iPhone app.", preferredStyle: .alert, actions: [okAction])
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
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    // MARK: - AmberAPI Delegate Methods
    
    func updatePrices() {
        // Update interface
        if let data = AmberAPI.shared.currentPriceData?.data {
            let priceRounded = Int(data.currentPriceKWH)
            self.mainLabel.setText("\(priceRounded)¢")
            self.circle.setBackgroundColor(Appearance.circleColour(from: data.currentPriceColor))
        }
    }
    
    func updateLoginDetails(requiresNewUserCredentials: Bool) {
        // Not implemented on Watch (doesn't show username/email in UI)
    }

}

