//
//  SingleChatTableViewCell.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 11/01/24.
//

import UIKit

class SingleChatTableViewCell: UITableViewCell {
    
    @IBOutlet weak var ChatName: UILabel!
    
    static let identifier = String(describing: SingleChatTableViewCell.self)

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
