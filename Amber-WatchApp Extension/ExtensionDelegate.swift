//
//  ExtensionDelegate.swift
//  Amber-WatchApp Extension
//
//  Created by Rowan Willson on 5/9/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date().nextMinutes(minutes: 15, plusSeconds: 5), userInfo: nil) { (error) in
            //successfully scheduled.
            //Note: There is an error in Apple documentation that says this completion handler is called for the actual refresh. This is incorrect - the handle() delegate method is called for the actual refresh event. Don't do anything in here.
        }
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AmberAPI.shared.update(completionHandler: nil)
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                AmberAPI.shared.update { (result) in
                    //schedule next update
                    WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date().nextMinutes(minutes: 15, plusSeconds: 5), userInfo: nil, scheduledCompletion: { (_) in
                        // schedule worked. As above per Apple docs error: this completion handler is called immediately. Do nothing in here.
                    })
                    //snapshot if there's new data. Otherwise signal completed work and don't snapshot.
                    let success = (result == .successFromNetwork || result == .successFromCache)
                    
                    //Update Complication with new data
                    if success {
                        let server = CLKComplicationServer.sharedInstance()
                        server.activeComplications?.forEach(server.reloadTimeline)
                    }
                    // Signal for new snapshot as required.
                    backgroundTask.setTaskCompletedWithSnapshot(success)
                }
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
