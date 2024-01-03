//
//  DatabaseManager.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 03/01/24.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
}


//MARK: User management
extension DatabaseManager {
    
    /// Validates if the user exists in the databse
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                 return
            }
            completion(true)
        })
    }
    
    ///Insert user in the database. To be called on register user screen
    public func insertUser(with user: ChatAppUser) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ])
        
    }
}
