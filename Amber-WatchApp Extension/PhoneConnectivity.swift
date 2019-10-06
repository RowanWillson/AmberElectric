//
//  PhoneConnectivity.swift
//  Amber-WatchApp Extension
//
//  Created by Rowan Willson on 5/9/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    /* Singleton */
    static let sharedManager = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private let session: WCSession = WCSession.default
    
    func startSession() {
        session.delegate = self
        session.activate()
    }
    

    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        
    }
    
    // Receive data here from iPhone app (UserDefaults key+data pairs). Insert into local UserDefaults.
    // Used for username & password and Complication Data
    // TODO: Process Complication data ...
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        let defaults = UserDefaults.shared
        for credential in userInfo {
            defaults.set(credential.value, forKey: credential.key)
        }
        defaults.synchronize()
        AmberAPI.shared.update(completionHandler: nil)
    }

    // MARK: - Delegate method
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if DEBUG
        print("WCSession Activated")
        #endif
    }
}
