//
//  Conversation.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 23/01/24.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let message: String
    let isRead: Bool
}
