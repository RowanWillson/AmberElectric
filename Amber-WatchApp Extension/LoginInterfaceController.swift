//
//  LoginInterfaceController.swift
//  Amber-WatchApp Extension
//
//  Created by Rowan Willson on 19/10/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import WatchKit
import Foundation


class LoginInterfaceController: WKInterfaceController {

    @IBOutlet weak var emailTextField: WKInterfaceTextField!
    @IBOutlet weak var passwordTextField: WKInterfaceTextField!
    
    private var emailText : String?
    private var passwordText : String?
    
    @IBAction func loginPressed() {
        //Save new credentials to Defaults
        let defaults = UserDefaults.shared
        defaults.set(emailText, forKey: DefaultsKeys.usernameKey)
        defaults.set(passwordText, forKey: DefaultsKeys.passwordKey)
        defaults.synchronize()
        
        // Ask network to login again
        AmberAPI.shared.update(completionHandler: nil)
        
        // Dismiss this view
        self.dismiss()
    }
    
    @IBAction func emailTextFieldAction(_ value: NSString?) {
        emailText = value as String?
    }
    
    @IBAction func passwordTextFieldAction(_ value: NSString?) {
        passwordText = value as String?
    }

}
