//
//  AppDefaults.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 14/01/24.
//

import Foundation


struct DefaultValues {
    static let email = "email"
    static let profilePicture = "profile_picture"
}

class AppDefaults {
    static let shared = AppDefaults()
    private var userDefaults = UserDefaults.standard
    
    var email: String? {
        get {
            return userDefaults.string(forKey: DefaultValues.email)
        }
        set {
            userDefaults.setValue(newValue, forKey: DefaultValues.email)
            userDefaults.synchronize()
        }
    }
    var profilePicture: String? {
        get {
            return userDefaults.string(forKey: DefaultValues.profilePicture)
        }
        set {
            userDefaults.setValue(newValue, forKey: DefaultValues.profilePicture)
            userDefaults.synchronize()
        }
    }
}
