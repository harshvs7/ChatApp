//
//  ConversationTableViewCell.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 23/01/24.
//

import UIKit
import SDWebImage

class NewConversationTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var userImageView: UIImageView!
    

    static let identifier = String(describing: NewConversationTableViewCell.self)

    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.cornerRadius = userImageView.frame.height / 2
    }
    
    public func configure(with model: SearchUserResult) {
        let path = "images/\(model.email)_profile_picture.png"
        userNameLabel.text = model.name

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
