//
//  LoginViewController.swift
//  Amber Electric
//
//  Created by Rowan Willson on 2/9/19.
//  Copyright © 2019 Rowan Willson. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    var errorText : String? {
        didSet {
            errorTextLabel.text = errorText
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(vStack)
        vStack.addArrangedSubview(logoImageView)
        vStack.addArrangedSubview(usernameTextField)
        vStack.addArrangedSubview(passwordTextField)
        vStack.addArrangedSubview(loginButton)
        vStack.addArrangedSubview(errorTextLabel)
        vStack.addArrangedSubview(UIView())  //bottom padding
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self.view!, attribute: .topMargin, relatedBy: .equal, toItem: vStack, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.view!, attribute: .centerX, relatedBy: .equal, toItem: vStack, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: vStack, attribute: .width, relatedBy: .equal, toItem: self.view!, attribute: .width, multiplier: 0.7, constant: 0.0),
            NSLayoutConstraint(item: vStack, attribute: .height, relatedBy: .equal, toItem: self.view!, attribute: .height, multiplier: 0.6, constant: 0.0)
        ])
        
        // Load existing values (if any)
        usernameTextField.text = UserDefaults.shared.string(forKey: DefaultsKeys.usernameKey)
        passwordTextField.text = UserDefaults.shared.string(forKey: DefaultsKeys.passwordKey)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        usernameTextField.becomeFirstResponder()  //present keyboard immediately
    }
    
    
    // MARK - Views
    
    private lazy var vStack : UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 50, leading: 0, bottom: 0, trailing: 0)
        stack.spacing = UIStackView.spacingUseSystem
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var logoImageView : UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "Logo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit  //don't stretch
        return imageView
    }()
    
    private lazy var usernameTextField : UITextField = {
        let textField = UITextField()
        textField.textContentType = .username
        textField.placeholder = "Username / Email"
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.keyboardType = UIKeyboardType.emailAddress
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.returnKeyType = UIReturnKeyType.next
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.font = UIFont.systemFont(ofSize: 18.0)
        return textField
    }()
    
    private lazy var passwordTextField : UITextField = {
        let textField = UITextField()
        textField.textContentType = .password
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.returnKeyType = UIReturnKeyType.go
        textField.font = UIFont.systemFont(ofSize: 18.0)
        textField.delegate = self
        return textField
    }()
    
    private lazy var loginButton : UIButton = {
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.titleLabel?.textColor = .black
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.layer.cornerRadius = 6.0
        button.backgroundColor = Appearance.amberLightBlue
        button.addTarget(self, action: #selector(loginButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var errorTextLabel : UILabel = {
        let textLabel = UILabel()
        textLabel.text = errorText
        textLabel.numberOfLines = 0 //multi-line support
        textLabel.font = UIFont.systemFont(ofSize: 16.0)
        textLabel.textColor = Appearance.amberPriceRed
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        return textLabel
    }()
    
    
    // MARK: - Login Action
    
    @objc private func loginButtonPressed() {
        let defaults = UserDefaults.shared
        defaults.set(usernameTextField.text, forKey: DefaultsKeys.usernameKey)
        defaults.set(passwordTextField.text, forKey: DefaultsKeys.passwordKey)
        defaults.synchronize()
        AmberAPI.shared.update(completionHandler: nil)
        self.dismiss(animated: true) {
            LoginViewController.sendLoginDetailsToWatch(force: true)
        }
    }
    
    static func sendLoginDetailsToWatch(force : Bool) {
        // Send username & password to Apple Watch extension
        let defaults = UserDefaults.shared
        if force || !defaults.bool(forKey: DefaultsKeys.sentLoginDetailsToWatch) {
            WatchSessionManager.sharedManager.startSession()
            if let username = defaults.string(forKey: DefaultsKeys.usernameKey), let password = defaults.string(forKey: DefaultsKeys.passwordKey) {
                WatchSessionManager.sharedManager
                    .transferToWatch(userInfo: [DefaultsKeys.usernameKey:username,DefaultsKeys.passwordKey:password])
            }
            if !force {
                defaults.set(true, forKey: DefaultsKeys.sentLoginDetailsToWatch)
                defaults.synchronize()
            }
        }
    }
    
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder() //transfer control
        } else if textField == passwordTextField {
            textField.resignFirstResponder() //hide keyboard
            loginButtonPressed()
        }
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)  //highlight/select text when tapping into textField
    }
    
}
