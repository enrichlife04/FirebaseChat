//
//  User.swift
//  ChatappWithFireBase
//
//  Created by Koichi Muranaka on 2020/12/28.
//

import Foundation
import Firebase

class User {
    
    let email: String
    let username: String
    let cretedAt: Timestamp
    let profileImageUrl: String
    
    var uid: String?
    
    init(dic: [String: Any]) {
        self.email = dic["email"] as? String ?? ""
        self.username = dic["username"] as? String ?? ""
        self.cretedAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.profileImageUrl = dic["profileImageUrl"] as? String ?? ""
        
    }
    
}

