//
//  WatchConnectivity.swift
//  Amber Electric
//
//  Created by Rowan Willson on 5/9/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    var dataToSend : [String:Any]?
    
    /* Singleton */
    static let sharedManager = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    private var validSession: WCSession? {
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }
    
    func startSession() {
        session?.delegate = self
        session?.activate()
    }
    
    /* Use this method to transfer data to Apple Watch extension. e.g.
    try WatchSessionManager.sharedManager.updateApplicationContext(["myKey" : myData])
     */
    func transferToWatch(userInfo: [String : Any]) {
        if let session = validSession, session.activationState == .activated {
            try? session.updateApplicationContext(userInfo)
            //session.transferUserInfo(userInfo)  //send immediately if connected
        } else {
            dataToSend = userInfo  //otherwise queue for sending once didComplete delegate method is called. Only handles 1 item.
        } 
    }
    
    /* Use this method to opportunistically transfer latest price to watch complication.
     TODO: On Watch, also re-schedule background refresh for +15 minutes as we have just given it fresh data from iPhone.
     Note: Apple documentation suggests calling this method max 50 times per day.
    */
    func updateWatchComplication(userInfo: [String : Any]) {
        if let session = validSession, session.isComplicationEnabled {
            session.transferCurrentComplicationUserInfo(userInfo)
        }
    }
    
    // MARK: - Delegate Methods
    
    /* Send queued up data */
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated, let data = dataToSend {
            session.transferUserInfo(data)
        }
        dataToSend = nil
    }
    
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // empty
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // empty
    }
    
}
