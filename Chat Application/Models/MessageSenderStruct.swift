//
//  Message.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 11/01/24.
//

import Foundation
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var senderId: String
    var photoUrl: String
    var displayName: String
}
