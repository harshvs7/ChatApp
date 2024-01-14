//
//  ChatViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 11/01/24.
//

import UIKit
import MessageKit

class ChatViewController: MessagesViewController {

    private var messages = [Message]()
    private var selfSender = Sender(senderId: "1", photoUrl: "", displayName: "Harsh")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

//MARK: helper functions
extension ChatViewController {
    private func setupUI() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("hello")))
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("hellohellohellohellohellohello")))
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("hellohellohellohellohellohellohellohellohellohellohello")))

    }
}

//MARK: Delegate Methods
extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
