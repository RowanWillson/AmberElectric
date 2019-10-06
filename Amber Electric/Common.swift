//
//  Common.swift
//  Amber Electric
//
//  Created by Rowan Willson on 31/8/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import Foundation
import UIKit

/* Global Colours */
enum Appearance {
    static let amberBlue = UIColor(red: 19.0/255.0, green: 36.0/255.0, blue: 53.0/255.0, alpha: 1.0)
    static let amberLightBlue = UIColor(red: 20.0/255.0, green: 208.0/255.0, blue: 1.0, alpha: 1.0)
    static let amberGreen = UIColor(red: 20.0/255.0, green: 1.0, blue: 168.0/255.0, alpha: 1.0)
    static let amberGrayInactive = UIColor.lightGray
    
    // Price circles
    static let amberPriceGreen = UIColor(red: 104.0/255.0, green: 219.0/255.0, blue: 155.0/255.0, alpha: 1.0)
    static let amberPriceYellow = UIColor(red: 243.0/255.0, green: 176.0/255.0, blue: 64.0/255.0, alpha: 1.0)
    static let amberPriceRed = UIColor(red: 208.0/255.0, green: 73.0/255.0, blue: 67.0/255.0, alpha: 1.0)
    
    static func circleColour(from name : String?) -> UIColor? {
        guard let name = name else {
            return nil
        }
        switch name {
        case "green":
            return Appearance.amberPriceGreen
        case "yellow":
            return Appearance.amberPriceYellow
        case "red":
            return Appearance.amberPriceRed
        default:
            return nil
        }
    }
}

/* Catchy tag lines */
enum MarketingText {
    static let priceGreenText = """
            It's
            cheap and green
            to use energy right now
            """
    static let priceYellowText = """
            It’s
            about normal prices now
            a normal time for normal use
            """
    static let priceRedText = """
            It’s
            expensive and dirty now
            use less and save more
            """
    
    static func marketingText(from name : String) -> String? {
        switch name {
        case "green":
            return MarketingText.priceGreenText
        case "yellow":
            return MarketingText.priceYellowText
        case "red":
            return MarketingText.priceRedText
        default:
            return nil
        }
    }

}

/* UserDefaults keys */
enum DefaultsKeys {
    static let usernameKey = "username"
    static let passwordKey = "password"
    static let lastSavedPriceKey = "lastPrice"
    static let lastSavedAuthKey = "lastAuth"
    static let sentLoginDetailsToWatch = "sentToWatch"
}

/* Setup in Capabilities > App Groups. Required to share UserDefaults data between Host app & Extension */
extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.com.amber.AmberElectric") ?? UserDefaults.standard
}

/* Grab Date of next X whole minutes, e.g. 30, 00 */
extension Date {
    func nextMinutes(minutes : Double = 30.0, plusSeconds seconds : TimeInterval = 0) -> Date {
        let timestamp = self.timeIntervalSinceReferenceDate
        let current = timestamp - fmod(timestamp, minutes*60.0)  //round down to whole X mins
        let next = current + minutes*60.0 + seconds  //add 5 seconds to ensure API request performed *after* server updated with new times.
        return Date(timeIntervalSinceReferenceDate: next)
    }
}

/* Custom DateFormatter object to use with Amber API responses.
 Use Brisbane for AEMO standardised time. Note: Amber API incorrectly returns 'Z' (UTC) timezone, which we ignore. */
extension DateFormatter {
    static let amberDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"  //2019-09-09T09:30:00Z
        dateFormatter.timeZone = TimeZone(identifier: "Australia/Brisbane")
        return dateFormatter
    }()
}
