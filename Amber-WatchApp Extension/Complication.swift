//
//  ComplicationController.swift
//  Amber WatchKit Extension
//
//  Created by Rowan Willson on 8/9/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import ClockKit
import WatchKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward, .backward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        
        // API Class loads latest cached data (from UserDefaults) on init:
        let priceData = AmberAPI.shared.currentPriceData?.data
        let priceColour = Appearance.circleColour(from: priceData?.currentPriceColor) ?? Appearance.amberGrayInactive
        var text = "⚡"
        if let price = priceData?.currentPriceKWH {
            text = "\(Int(price))¢"
        } else {
            // No current data. Schedule a background refresh so we can get data and update ASAP.
            #if DEBUG
            print("\(Date().description): No data for complication. Scheduling background refresh")
            #endif
            WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(), userInfo: nil) { (_) in  // Instant: - grab updated data and reload complication.
                //successfully scheduled
            }
        }
        
        #if DEBUG
        print("\(Date().description): Updating Complication: " + text)
        #endif
        
        let textProvider = CLKSimpleTextProvider(text: text)
        textProvider.tintColor = priceColour
        
        switch(complication.family) {
            
            // TODO: Add more complications!!   Simply add more cases and fill out the appropriate text providers. Don't forget to tick supported complication types in Project Settings under Watch Extension target.
            
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallSimpleText()
            template.tintColor = priceColour
            template.textProvider = textProvider
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
            
        case .extraLarge:
            let template = CLKComplicationTemplateExtraLargeSimpleText()
            template.tintColor = priceColour
            template.textProvider = textProvider
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
            
        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
            template.tintColor = priceColour
            template.centerTextProvider = textProvider
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
            
        case .utilitarianSmallFlat:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.tintColor = priceColour
            template.textProvider = textProvider
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
            
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallSimpleText()
            template.textProvider = textProvider
            template.tintColor = priceColour
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
            
        default:
            handler(nil) // Handle any non-supported families.
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
    
}
