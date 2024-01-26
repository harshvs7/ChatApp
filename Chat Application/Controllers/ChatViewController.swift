//
//  ChatViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 11/01/24.
//

import UIKit
import PhotosUI
import MessageKit
import InputBarAccessoryView
import SDWebImage

class ChatViewController: MessagesViewController {
    
    private var messages = [Message]()
    private var conversationID: String?
    public var isNewConversation = false
    private let receiverEmailAddress: String?
    private let receiverName: String?
    private var selfSender: Sender? {
        guard let senderId = AppDefaults.shared.email,
              let senderName = AppDefaults.shared.name else { return nil }
        let safeEmail = DatabaseManager.safeEmail(with: senderId)
        return Sender(senderId: safeEmail, photoUrl: "", displayName: senderName )
        
    }
    
    public static var  dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    
    init(with email: String, with name: String, with conversationID: String?) {
        self.receiverEmailAddress = email
        self.conversationID = conversationID
        self.receiverName = name
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
        if let id = conversationID {
            listenMessages(with: id,with: true)
        }
    }
}

//MARK: helper functions
extension ChatViewController {
    private func setupUI() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setpInputButton()
    }
    
    private func createMessageId(with date: Bool) -> String? {
        guard let userEmail = AppDefaults.shared.email,
              let receiverEmailAddress = self.receiverEmailAddress else {
            return nil
        }
        let safeUserEmail = DatabaseManager.safeEmail(with: userEmail)
        //        if date {
        //            let dateString = Self.dateFormatter.string(from: Date())
        //            let messageId = "\(receiverEmailAddress)_\(safeUserEmail)_\(dateString)"
        //        }
        //        let dateString = Self.dateFormatter.string(from: Date())
        let messageId = "\(receiverEmailAddress)_\(safeUserEmail)"
        return messageId
        
    }
    
    private func listenMessages(with id: String, with scrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if scrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("error fetching the message \(error)")
            }
        })
    }
    
    private func setpInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.onTouchUpInside() { [weak self] _ in
            self?.messageInputBar.resignFirstResponder()
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: CGFloat(30 ), animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
}

//MARK: Handling the Media attachment
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet( )
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet,animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Select the source",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            self?.openCamera( )
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library  ", style: .default, handler: { [weak self] _ in
            self?.openPhotoLibrary()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet,animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Select the source",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            self?.openCamera( )
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Library  ", style: .default, handler: { [weak self] _ in
            self?.openPhotoLibrary()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet,animated: true)
    }
    
    private func openCamera() {
        
        let cameraVC = UIImagePickerController()
        cameraVC.delegate = self
        cameraVC.sourceType = .camera
        cameraVC.allowsEditing = true
        cameraVC.mediaTypes = ["public.movie"]
        cameraVC.videoQuality = .typeMedium
        present(cameraVC,animated: true)
    }
    
    private func openPhotoLibrary() {
        
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 1
        let photoVC = PHPickerViewController(configuration: configuration)
        photoVC.delegate = self
        
        present(photoVC,animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let item = results.first?.itemProvider else { return }
        
        if item.canLoadObject(ofClass: UIImage.self) {
            item.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                if let error {
                    self?.showAlert(with: "Error", with: error.localizedDescription, with: "Dismiss")
                }
                if let image = image as? UIImage {
                    self?.uploadImage(image: image)
                }
            }
        } else if item.canLoadObject(ofClass: URL.self) {
            item.loadObject(ofClass: URL.self) { [weak self] asset, error in
                if let error = error {
                    self?.showAlert(with: "Error", with: error.localizedDescription, with: "Dismiss")
                }
                if let asset = asset {
                    self?.uploadVideo(asset: asset)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.editedImage] as? UIImage  {
            uploadImage(image: selectedImage)
        } else if let selectedVideo = info[.mediaURL] as? URL {
            uploadVideo(asset: selectedVideo)
        }
    }
    
    private func uploadImage(image: UIImage) {
        guard let imageData = image.pngData(),
              let messageId = createMessageId(with: true),
              let conversationID = conversationID,
              let name = receiverName,
              let selfSender = selfSender,
              let receiverEmailAddress = receiverEmailAddress else { return }
        
        
        let fileName = "photo_message" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
        StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { result in
            switch result {
            case .success(let url):
                print("Uploaded message photo  \(url)")
                guard let url = URL(string: url),
                      let placeHolder = UIImage(systemName: "plus") else { return }
                
                let media = Media(url: url,
                                  image: nil,
                                  placeholderImage: placeHolder,
                                  size: .zero)
                
                let message = Message(sender: selfSender,
                                      messageId: messageId,
                                      sentDate: Date(),
                                      kind: .video(media))
                
                DatabaseManager.shared.sendMessage(conversationId: conversationID,
                                                   otherUserEmail: receiverEmailAddress,
                                                   name: name,
                                                   newMessage: message,
                                                   completion: { success in
                    if success {
                        print( "sent the Video messgae")
                    } else {
                        print(" failed to send the Video message")
                    }
                })
                
            case .failure(let error):
                print("error in upload the message video \(error)")
            }
        })
    }
    
    private func uploadVideo(asset: URL) {
        guard let messageId = createMessageId(with: true),
              let conversationID = conversationID,
              let name = receiverName,
              let selfSender = selfSender,
              let receiverEmailAddress = receiverEmailAddress else { return }
        
        let fileName = "video_message" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
        StorageManager.shared.uploadMessageVideo(with: asset, fileName: fileName, completion: { result in
            switch result {
            case .success(let url):
                print("Uploaded message vidoo \(url)")
                guard let url = URL(string: url),
                      let placeHolder = UIImage(systemName: "plus") else { return }
                
                let media = Media(url: url,
                                  image: nil,
                                  placeholderImage: placeHolder,
                                  size: .zero)
                
                let message = Message(sender: selfSender,
                                      messageId: messageId,
                                      sentDate: Date(),
                                      kind: .photo(media))
                
                DatabaseManager.shared.sendMessage(conversationId: conversationID,
                                                   otherUserEmail: receiverEmailAddress,
                                                   name: name,
                                                   newMessage: message,
                                                   completion: { success in
                    if success {
                        print( "sent the photo messgae")
                    } else {
                        print(" failed to send the photo message")
                    }
                })
                
            case .failure(let error):
                print("error in upload the message photo \(error)")
            }
        })
    }
}

//MARK: MessageKit Delegate Methods
extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("UserMail not found")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else { return }
        
        switch message.kind {
        case .photo(let mediaItem):
            guard let url = mediaItem.url else { return }
            imageView.sd_setImage(with: url)
        default:
            break
        }
    }
}

//MARK: Tapping into the imaageView
extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let mediaItem):
            guard let url = mediaItem.url else { return }
            let vc = PhotoViewerViewController(url: url)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}

//MARK: InputBar Delegates
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let receiverEmailAddress = self.receiverEmailAddress,
              let receiverName = self.receiverName,
              let messageId = createMessageId(with: false) else { return }
        print("message to be sent.....\(text)")
        let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        if isNewConversation {
            //create newConversation
            DatabaseManager.shared.createNewConversation( with: receiverEmailAddress, with: receiverName, with: message, completion: { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                    self?.messageInputBar.inputTextView.text = ""
                    self?.messagesCollectionView.reloadData()
                } else {
                    print("failed to send the message ")
                }
            })
        } else {
            //append to existing conversation
            guard let conversationID = conversationID,
                  let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(conversationId: conversationID, otherUserEmail: receiverEmailAddress, name: name, newMessage: message, completion: { [weak self] success in
                if success {
                    print("message sent")
                    self?.messageInputBar.inputTextView.text = ""
                } else {
                    print("Failed to send the message")
                }
            })
        }
    }
}
