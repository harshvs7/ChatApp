//
//  DatabaseManager.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 03/01/24.
//

import Foundation
import FirebaseDatabase
import MessageKit

public enum DatabaseError: Error {
    case failedToFetch
}

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    static func safeEmail( with emailAddress: String) -> String {
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

//MARK: Fetching user info
extension DatabaseManager {
    
    public func getInfoFor(with path: String, completion: @escaping (Result<Any, Error>) -> Void ) {
        database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value  = snapshot.value else {
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
    public func createNewConversation(with receiverEmail: String,with name: String, with firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let senderEmail = AppDefaults.shared.email,
              let senderName = AppDefaults.shared.name else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(with: senderEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
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
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read":false
                ]
            ]
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "receiver_email": safeEmail,
                "name": senderName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read":false
                ]
            ]
            //Updating the current users conversation module
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error,_ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversations(name: name,conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                })
                
            } else {
                userNode["conversations"] = [ newConversationData ]
                ref.setValue(userNode, withCompletionBlock: { [weak self] error,_ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversations(name: name, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
            
            //updating the recipients conversation
            self?.database.child("\(receiverEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(receiverEmail)/conversations").setValue([recipient_newConversationData])
                    
                } else {
                    //create
                    self?.database.child("\(receiverEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
        })
        
    }
    
    private func finishCreatingConversations(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let senderEmail = AppDefaults.shared.email else {
            completion(false)
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(with: senderEmail)
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
            "is_read": false,
            "name": name
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
    public func getAllConversations(with email: String, completion: @escaping (Result<[Conversation],Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["receiver_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let message = latestMessage["message"] as? String,
                      let date = latestMessage["date"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool
                else {
                    return nil
                }
                
                let latestMessageObject =  LatestMessage(date: date, message: message, isRead: isRead)
                
                return Conversation(id: conversationID, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            })
            
            completion(.success(conversations))
            
            
        })
        
    }
    
    ///Get All messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message],Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let id = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString)
                else {
                    return nil
                }
                var kind: MessageKind?
                if type == "text" {
                    kind = .text(content)
                } else if type == "photo" {
                    guard let url = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else { return nil }
                    let media = Media(url: url, image: nil , placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    guard let url = URL(string: content),
                          let placeholder = UIImage(systemName: "play") else { return nil }
                    let media = Media(url: url, image: nil , placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                guard let finalKind = kind else { return nil }
                let sender = Sender(senderId: senderEmail, photoUrl: "", displayName: name)
                
                return Message(sender: sender, messageId: id, sentDate: date, kind: finalKind)
            })
            completion(.success(messages))
        })
    }
    
    ///Sends a message with target Conversation and message
    public func sendMessage(conversationId: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        database.child("\(conversationId)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var currentMessage = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            guard let senderEmail = AppDefaults.shared.email else {
                completion(false)
                return
            }
            let safeSenderEmail = DatabaseManager.safeEmail(with: senderEmail)
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                guard let url = mediaItem.url?.absoluteString else { return }
                message = url 
                break
            case .video(let mediaItem):
                guard let url = mediaItem.url?.absoluteString else { return }
                message = url
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
            
            let newMessageEntry: [String: Any] = [
                "id": conversationId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": safeSenderEmail,
                "is_read": false,
                "name": name
            ]
            
            currentMessage.append(newMessageEntry)
            self?.database.child("\(conversationId)/messages").setValue(currentMessage, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self?.database.child("\(safeSenderEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    let updatedMessage: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    var targetConversation: [String: Any]?
                    var position = 0
                    for conversation in currentUserConversations {
                        if let currentId = conversation["id"] as? String, currentId == conversationId {
                            targetConversation = conversation
                            break
                        }
                        position += 1
                    }
                    targetConversation?["latest_message"] = updatedMessage
                    guard let targetConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    currentUserConversations[position] = targetConversation
                    self?.database.child("\(safeSenderEmail)/conversations").setValue(currentUserConversations,withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            let updatedMessage: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            var finalConversation: [String: Any]?
                            var position = 0
                            for conversation in otherUserConversations {
                                if let currentId = conversation["id"] as? String, currentId == conversationId {
                                    finalConversation = conversation
                                    break
                                }
                                position += 1
                            }
                            finalConversation?["latest_message"] = updatedMessage
                            guard let targetConversation = finalConversation else {
                                completion(false)
                                return
                            }
                            otherUserConversations[position] = targetConversation
                            self?.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations,withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
                
            })
            
        })
    }
}
