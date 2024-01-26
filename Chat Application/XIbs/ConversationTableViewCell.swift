//
//  ConversationTableViewCell.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 23/01/24.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var userMessageLabel: UILabel!
    @IBOutlet private weak var userImageView: UIImageView!
    @IBOutlet private weak var messageTimeLabel: UILabel!
    

    static let identifier = String(describing: ConversationTableViewCell.self)
    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
////        userImageView.cornerRadius = userImageView.frame.width / 2
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    public func configure(with model: Conversation) {
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        self.userNameLabel.text = model.name
        self.userMessageLabel.text = model.latestMessage.message
        self.messageTimeLabel.text = String(model.latestMessage.date.split(separator: " ")[2].prefix(5))
        StorageManager.shared.downloadURL(with: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url)
                }
            case .failure(let error):
                print("error fetching other user profile \(error)")
            }
        })
    }
}
