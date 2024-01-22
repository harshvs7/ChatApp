//
//  ChatViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 11/01/24.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {

    private var messages = [Message]()
    public var isNewConversation = false
    private let receiverEmailAddress: String?
    private var selfSender: Sender? {
        guard let senderId = AppDefaults.shared.email else { return nil }
        return Sender(senderId: senderId, photoUrl: "", displayName: "Harsh")
        
    }
    
    public static var  dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    
    init(with email: String) {
        self.receiverEmailAddress = email
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

//MARK: helper functions
extension ChatViewController {
    private func setupUI() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.delegate = self
    }
    private func createMessageId() -> String? {
        guard let userEmail = AppDefaults.shared.email,
              let receiverEmailAddress = self.receiverEmailAddress else {
            return nil
        }
        let safeUserEmail = DatabaseManager.shared.safeEmail(with: userEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let messageId = "\(receiverEmailAddress)_\(safeUserEmail)_\(dateString )"
        return messageId
        
    }
}

//MARK: MessageKit Delegate Methods
extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("UserMail not found")
        return Sender(senderId: "senderId", photoUrl: "", displayName: "Harsh")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
}

//MARK: InputBar Delegates
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = self.selfSender,
        let receiverEmailAddress = self.receiverEmailAddress,
        let messageId = createMessageId() else { return }
        print("message to be sent.....\(text)")
        if isNewConversation {
            //create newConversation
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
            DatabaseManager.shared.createNewConversation(with: receiverEmailAddress, with: message, completion: { success in
                if success {
                    print("message sent")
                } else {
                    print("failed to send the message ")
                }
            })
        } else {
            //append to existing conversation
        }
    }
}
