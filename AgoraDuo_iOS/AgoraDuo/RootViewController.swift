//
//  RootViewController.swift
//  AgoraDuo
//
//  Created by Qin Cindy on 9/21/16.
//  Copyright © 2016 Qin Cindy. All rights reserved.
//

import UIKit



class RootViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Configuration.sharedInstance.myPhoneNumber == nil {
            if let vc = create(LoginViewController.classForCoder()) {
                loadViewController(vc, self.view)
            }
        } else {
            Agora.sharedInstance.updateDelegate = { status in
                
                DispatchQueue.main.async(execute: {
                    if status == .login {
                        if let vc = self.create(CallViewController.classForCoder()) {
                            self.loadViewController(vc, self.view)
                        }
                    } else {
                        if let vc = self.create(LoginViewController.classForCoder()) {
                            self.loadViewController(vc, self.view)
                        }
                    }
                })
                
            }
            Agora.sharedInstance.login()

        }
        
    }
}
    

