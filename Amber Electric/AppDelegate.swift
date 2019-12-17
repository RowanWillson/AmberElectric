//
//  AppDelegate.swift
//  Amber Electric
//
//  Created by Rowan Willson on 31/8/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Background app fetch - every 15 minutes
        UIApplication.shared.setMinimumBackgroundFetchInterval(15*60)
        
        // Request local notification support from user
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { (granted, error) in
            // Optional: Enable or disable features based on authorization.
        }
        return true
    }
    
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Download new data
        AmberAPI.shared.update { (result) in
            if result == .successFromNetwork {
                // Local Notification if new price less than zero!
                if let price = AmberAPI.shared.currentPriceData?.data.currentPriceKWH, (price < 0.0 || price > 200.0) {
                    self.sendPriceNotification()
                }
                completionHandler(.newData)
            } else if result == .successFromCache {
                completionHandler(.noData)
            } else {
                completionHandler(.failed)  // auth or network error
            }
        }
    }
    
    // Local notification when prices < $0.00. Called no more than every 15mins during app fetch.
    private func sendPriceNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getNotificationSettings { (settings) in
            // Do not schedule notifications if not authorized.
            guard settings.authorizationStatus == .authorized else {return}
            
            if settings.alertSetting == .enabled {
                if let price = AmberAPI.shared.currentPriceData?.data.currentPriceKWH {
                    // Schedule an alert-only notification (no sound)
                    let content = UNMutableNotificationContent()
                    content.title = "Price Alert!"
                    content.body = "Amber electricity price \(Int(price))¢"
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                    let uuidString = UUID().uuidString
                    let request = UNNotificationRequest(identifier: uuidString,
                                                        content: content, trigger: trigger)
                    let notificationCenter = UNUserNotificationCenter.current()
                    notificationCenter.add(request, withCompletionHandler: nil)
                }
            }
        }
    }

}

