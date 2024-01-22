//
//  DatabaseManager.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 03/01/24.
//

import Foundation
import FirebaseDatabase

public enum DatabaseError: Error {
    case failedToFetch
}

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    func safeEmail( with emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
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
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void ) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ],withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var userCollection = snapshot.value as? [[String: String]] {
                    let newElement: [String: String] = [
                        "name": user.firstName + " " + user.lastName,
                        "safe_email": user.safeEmail
                    ]
                    userCollection.append(newElement)
                    self.database.child("users").setValue(userCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                } else {
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "safe_email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                
            })
        })
        
    }
    
    ///Fetching all the users for newConversatino screen
    public func getAllUsers(completion: @escaping (Result<[[String: String]],Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String ]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
            
        })
    }
    
}

//MARK: Handling messages and conversations
extension DatabaseManager {
    
    /// Creates new conversation in the database when firstMessage is sent
    public func createNewConversation(with receiverEmail: String, with firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let senderEmail = AppDefaults.shared.email else {
            return
        }
        let safeEmail = DatabaseManager.shared.safeEmail(with: senderEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationId = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "receiver_email": receiverEmail,
                "latest_email": [
                    "date": dateString,
                    "message": message,
                    "is_read":false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error,_ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversatios(conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                })
                
            } else {
                userNode["conversations"] = [ newConversationData ]
                ref.setValue(userNode, withCompletionBlock: { [weak self] error,_ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversatios(conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
            
        })
        
    }
    
    private func finishCreatingConversatios(conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let senderEmail = AppDefaults.shared.email else {
            completion(false)
            return
        }
        let safeSenderEmail = DatabaseManager.shared.safeEmail(with: senderEmail)
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        let conversationMessage: [String: Any] = [
            "id": conversationID,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": safeSenderEmail,
            "is_read": false
        ]
        let value: [String: Any] = [
            "messages": [
                conversationMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error,_ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
        
        
    }
    
    ///Fetches and returns all conversations for a user with an email
    public func getAllConversations(with email: String, completion: @escaping (Result<String,Error>) -> Void) {
        
    }
    
    ///Get All messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String,Error>) -> Void) {
        
    }
    
    ///Sends a message with target Conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
}
