//
//  LoginViewController.swift
//  AgoraDuo
//
//  Created by Qin Cindy on 9/2/16.
//  Copyright © 2016 Qin Cindy. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneNumberTextField.keyboardType = .numberPad
        phoneNumberTextField.delegate = self
    }

    @IBAction func pressLoginButton(_ sender: UIButton) {
        if (phoneNumberTextField.text == nil || phoneNumberTextField.text == "") {
            SVProgressHUD.showError(withStatus: "请输入您的手机号码".localized())
        } else {
            Configuration.sharedInstance.myPhoneNumber = (phoneNumberTextField.text)!
            Agora.sharedInstance.updateDelegate = { status in
                
                DispatchQueue.main.async(execute: {
                    self.indicator?.stopAnimating()
                    if status == .login {
                        if let vc = self.create(CallViewController.classForCoder()) {
                            self.present(vc, animated: true, completion: nil)
                        }
                    }
                })
                
            }
            Agora.sharedInstance.login()
            showLoadingView()
        }
    }
    
    var indicator: UIActivityIndicatorView?
    func showLoadingView() {
        
        indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator!.center = view.center
        view.addSubview(indicator!)
        indicator?.startAnimating()

    }

}


extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

}
