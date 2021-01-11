//
//  ChatRoom.swift
//  ChatappWithFireBase
//
//  Created by Koichi Muranaka on 2020/12/31.
//

import Foundation
import Firebase

class ChatRoom {
    
    let latestMessageId: String
    let members: [String]
    let createdAt: Timestamp
    
    var latestMessage: Message?
    var documentId: String?
    var partnerUser: User?
    
    init(dic: [String:Any]) {
        self.latestMessageId = dic["latestMessageId"] as? String ?? ""
        self.createdAt = dic["createdAt"]as? Timestamp ?? Timestamp()
        self.members = dic["members"] as? [String] ?? [String]()
        
    }
}
