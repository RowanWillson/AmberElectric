//
//  Network.swift
//  Amber Electric
//
//  Created by Rowan Willson on 31/8/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import Foundation

/* How did our API request finish */
enum NetworkResult {
    case successFromNetwork, successFromCache, failWrongCredentials, failOther
}

/* JSON mapping from Auth API */
struct AuthData : Decodable, BinaryCodable {
    struct AuthPersonalData : Decodable, BinaryCodable {
        let name : String
        let postcode : String
        let email : String
        let idToken : String
        let refreshToken : String
    }
    let data : AuthPersonalData
    let serviceResponseType : Int
    let message : String?
}

/* JSON mapping from GetPriceList API */
struct CurrentPriceData : Decodable, BinaryCodable {
    struct PriceData : Decodable, BinaryCodable {
        struct Price : Decodable, BinaryCodable {
            let period : Date  // ISO-8601 e.g. 2019-08-31T22:00:00Z
            let priceKWH : Double
            let renewableInGrid : Double
            let color : String
        }
        let currentPriceKWH : Double
        let currentRenewableInGrid : Double
        let currentPriceColor : String
        let currentPricePeriod : Date   // ISO-8601
        let forecastPrices : [Price]
        let previousPrices : [Price]
    }
    let data : PriceData
    let serviceResponseType : Int
    let message : String?
}


/* JSON mapping from GetUsageForHub API */
struct HistoricalHubData : Decodable {
    struct HistData : Decodable {
        
        struct LongTermUsage : Decodable {
            let totalUsageInCertainPeriod : Double
            let totalUsageCostInCertainPeriod : Double
            let lessThanAverageCost : Double
            let lessThanAverageUsage : Double
            let savedCost : Double
            let usedPriceSpikesInCertainPeriod : Double
            let lessThanAveragePrice : Double
        }
        
        struct DailyUsage : Decodable {
            let date : Date // ISO 8601
            let usageType : String //e.g. "ACTUAL"
            let usageCost : Double
            let usageKWH : Double
            let usageAveragePrice : Double
            let usagePriceSpikes : Double
            let dailyFixedCost : Double
            let meterSuffix : String //e.g. "E1"
        }
        
        let currentNEMtime : Date // ISO-8601
        let thisWeekUsage : [String:LongTermUsage]
        let lastWeekUsage : [String:LongTermUsage]
        let lastMonthUsage: [String:LongTermUsage]
        
        let thisWeekDailyUsage : [DailyUsage]
        let lastWeekDailyUsage : [DailyUsage]
        let lastMonthDailyUsage : [DailyUsage]
        let usageDataTypes : [String]  // e.g. "E1"
    }
    
    let data : HistData
    let serviceResponseType : Int
    let message : String?
}


/* Delegate callbacks for various network completion events */
protocol AmberAPIDelegate : class {
    func updateLoginDetails(requiresNewUserCredentials : Bool)
    func updatePrices()
    func updateHistoricalUsage()
}

/* Implement empty updateHistoricalUsage here. Override to implement */
extension AmberAPIDelegate {
    func updateHistoricalUsage() { }
}

/* Singleton network class. Call AmberAPI.shared.update() to use it.
  Will login, download prices and call delegate throughout.
  Data is serialised and cached to disk via UserDefaults.
  This class will update itself every half hour with a timer (e.g. as Kiosk).
  Note: iOS Background app refresh should also call update() */
class AmberAPI {
    
    private static let authURL = "https://api-bff.amberelectric.com.au/api/v1.0/Authentication/SignIn"
    private static let priceURL = "https://api-bff.amberelectric.com.au/api/v1.0/Price/GetPriceList"
    private static let usageURL = "https://api-bff.amberelectric.com.au/api/v1.0/UsageHub/GetUsageForHub"
    
    private let jsonDecoder = JSONDecoder()
    
    /* Singleton: access as AmberAPI.shared */
    static let shared = AmberAPI()
    private init() {
        
        //Decode non-standard Amber API dates that are hard-coded to Brisbane timezone with incorrect 'Z' timezone.
        jsonDecoder.dateDecodingStrategy = .formatted(.amberDateFormatter)
        
        // Load some old currentPriceData from Defaults if it exists
        if let data = UserDefaults.shared.object(forKey: DefaultsKeys.lastSavedPriceKey) as? [UInt8] {
            currentPriceData = try? BinaryDecoder.decode(CurrentPriceData.self, data: data)
        }
        if let data = UserDefaults.shared.object(forKey: DefaultsKeys.lastSavedAuthKey) as? [UInt8] {
            authData = try? BinaryDecoder.decode(AuthData.self, data: data)
        }
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }

    weak var delegate : AmberAPIDelegate?
    
    private var timer : Timer?  //every 15 mins at xx:00:05 and xx:15:05
    
    /* Downloaded Data */
    var authData : AuthData?
    var currentPriceData : CurrentPriceData?
    var historicalHubData : HistoricalHubData?
    
    /* Update() - sets up timer. Will grab cached data if able. Signals delegate and completionHandler with result(s). */
    func update(completionHandler : ((_ result: NetworkResult) -> Void)?) {
        
        /* 15 minute timer */
        if timer == nil {
            timer = Timer(fire: Date().nextMinutes(minutes: 15, plusSeconds: 5), interval: 60*15, repeats: true, block: { (_) in
                self.login(completionHandler: nil)  //login again on next half hour boundary
            })
        }
        login(completionHandler: completionHandler)
    }
    
    
    /* Attempt Login. Upon successful login, calls prices.
     Optional completion handler is called upon successful login AND download of price data. Or upon return of cache results.
     Note: We always call login API and refresh token. With HTTP/2, this is a small time burden. */
    private func login(completionHandler : ((_ result: NetworkResult) -> Void)?) {

        let defaults = UserDefaults.shared

        /* Firstly check cached currentPriceData for a result in the current time block and return that if appropriate (avoid unnecessary network calls). Assumes data does not change in each 15 minute time period. */
        if let currentCachedTime = currentPriceData?.data.currentPricePeriod {
            let nextValidTimePeriod = currentCachedTime.nextMinutes(minutes: 15)
            if nextValidTimePeriod.timeIntervalSinceNow > 0 {
                #if DEBUG
                print("\(Date().description): Returning Cached Data: " + currentCachedTime.description + " \(currentPriceData?.data.currentPriceKWH ?? 0)c")
                #endif
                delegate?.updateLoginDetails(requiresNewUserCredentials: false)
                delegate?.updatePrices()
                completionHandler?(.successFromCache)
                return
            }
        }
        
        guard let authURL = URL(string: AmberAPI.authURL) else {
            completionHandler?(.failOther)
            return
        }
        
        // Get saved user credentials from UserDefaults
        guard let username = defaults.string(forKey: DefaultsKeys.usernameKey),
              let password = defaults.string(forKey: DefaultsKeys.passwordKey) else {
            
            delegate?.updateLoginDetails(requiresNewUserCredentials: true)
            completionHandler?(.failWrongCredentials)
            return
        }
        
        var request = URLRequest(url: authURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = "{\"username\":\"\(username)\",\"password\":\"\(password)\"}".data(using: .utf8)
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, let _ = response as? HTTPURLResponse, error == nil else {
                #if DEBUG
                print("error", error ?? "Network error in Auth")
                #endif
                completionHandler?(.failOther)
                return
            }
            if let auth = try? self.jsonDecoder.decode(AuthData.self, from: data), auth.serviceResponseType == 1 {
                DispatchQueue.main.async {
                    self.authData = auth
                    self.delegate?.updateLoginDetails(requiresNewUserCredentials: false)
                    
                    // Serialise to Defaults (cache) for next time.
                    let defaults = UserDefaults.shared
                    do {
                        let bytes = try BinaryEncoder.encode(auth)
                        defaults.set(bytes, forKey: DefaultsKeys.lastSavedAuthKey)
                        defaults.synchronize()
                    } catch {
                        #if DEBUG
                        print(error.localizedDescription)
                        #endif
                    }
                    
                    // Now we are logged in, next step is to get price data from API.
                    self.getPrices(completionHandler: completionHandler)
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate?.updateLoginDetails(requiresNewUserCredentials: true)
                    completionHandler?(.failOther)
                }
            }
        }
        dataTask.resume()
    }
    
    
    /* Get Prices. Upon successful completion, calls history API */
    private func getPrices(completionHandler : ((_ result: NetworkResult) -> Void)?) {
        guard let priceURL = URL(string: AmberAPI.priceURL) else {
            completionHandler?(.failOther)
            return
        }
        
        guard let idToken = authData?.data.idToken, let refreshToken = authData?.data.refreshToken, let email = authData?.data.email else {
            completionHandler?(.failOther)
            return
        }
        
        var request = URLRequest(url: priceURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(idToken, forHTTPHeaderField: "authorization")
        request.setValue(email, forHTTPHeaderField: "email")
        request.setValue(refreshToken, forHTTPHeaderField: "refreshtoken")
        request.httpMethod = "POST"
        request.httpBody = "{\"headers\":{\"normalizedNames\":{},\"lazyUpdate\":null,\"headers\":{}}}"
            .data(using: .utf8)
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, let _ = response as? HTTPURLResponse, error == nil else {
                #if DEBUG
                print("error", error ?? "Network error in Prices")
                #endif
                completionHandler?(.failOther)
                return
            }
            if let prices = try? self.jsonDecoder.decode(CurrentPriceData.self, from: data) {
                DispatchQueue.main.async {
                    self.currentPriceData = prices
                    self.delegate?.updatePrices()
                    
                    // Serialise to Defaults (cache) for next time.
                    let defaults = UserDefaults.shared
                    do {
                        let bytes = try BinaryEncoder.encode(prices)
                        defaults.set(bytes, forKey: DefaultsKeys.lastSavedPriceKey)
                        defaults.synchronize()
                    } catch {
                        #if DEBUG
                        print(error.localizedDescription)
                        #endif
                    }

                    //self.getHistory()  // Enable once implemented in UI
                    completionHandler?(.successFromNetwork)
                }
            } else {
                completionHandler?(.failOther)
            }
        }
        dataTask.resume()
    }
    
    /* Get Prices. Upon successful completion, calls history */
    private func getHistory(completionHandler : ((_ result: NetworkResult) -> Void)?) {
        guard let usageURL = URL(string: AmberAPI.usageURL) else {
            completionHandler?(.failOther)
            return
        }
        
        guard let idToken = authData?.data.idToken, let refreshToken = authData?.data.refreshToken, let email = authData?.data.email else {
            completionHandler?(.failOther)
            return
        }
        
        var request = URLRequest(url: usageURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(idToken, forHTTPHeaderField: "authorization")
        request.setValue(email, forHTTPHeaderField: "email")
        request.setValue(refreshToken, forHTTPHeaderField: "refreshtoken")
        request.httpMethod = "POST"
        request.httpBody = "{\"email\":\"\(email)\"}"
            .data(using: .utf8)
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, let _ = response as? HTTPURLResponse, error == nil else {
                #if DEBUG
                print("error", error ?? "Network error in History")
                #endif
                completionHandler?(.failOther)
                return
            }
            if let hubData = try? self.jsonDecoder.decode(HistoricalHubData.self, from: data) {
                DispatchQueue.main.async {
                    self.historicalHubData = hubData
                    self.delegate?.updateHistoricalUsage()
                    completionHandler?(.successFromNetwork)
                }
            } else {
                completionHandler?(.failOther)
            }
        }
        dataTask.resume()
    }
}
