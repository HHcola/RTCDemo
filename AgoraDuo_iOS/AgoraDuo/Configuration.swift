//
//  Configuration.swift
//  C&T Speaker
//
//  Created by Cindy Qin on 16/5/16.
//  Copyright © 2016年 YueStudio. All rights reserved.
//

import Foundation
/**
* Configuration reads config from configuration.plist in the app bundle
*
* @author Cindy Qin
*/
class Configuration: NSObject {
    

    var appid = "82e27d05f57a4673818306c37cfcb447"
    var certificate = "" // 79780a0d05a540a999ed9081b717779e

    var myPhoneNumber:String? {
        
        get {
            let userDefaults = UserDefaults.standard
            let key = "myPhoneNumber"
            return userDefaults.string(forKey: key)
        }
        set(newValue) {
            let userDefaults = UserDefaults.standard
            let key = "myPhoneNumber"
            userDefaults.set(newValue, forKey: key)
            userDefaults.synchronize()
        }
    }


    /// shared instance of Configuration (singleton)
    static let sharedInstance = Configuration()

    /**
    Reads configuration file
    */
    override init() {
        super.init()
        self.readConfigs()
    }
    
    // MARK: private methods
    
    /**
    * read configs from plist
    */
    func readConfigs() {
        if let path = getConfigurationResourcePath() {
            let configDicts = NSDictionary(contentsOfFile: path)
            

            if let appid = configDicts?["appid"] as? String {
                self.appid = appid
            }
            if let certificate = configDicts?["certificate"] as? String {
                self.certificate = certificate
            }
            
        }
        else {
            assert(false, "configuration is not found")
        }
    }
    
    /**
    Get the path to the configuration.plist.
    
    - returns: the path to configuration.plist
    */
    func getConfigurationResourcePath() -> String? {
        return Bundle(for: Configuration.classForCoder()).path(forResource: "Configs", ofType: "plist")
    }
}
