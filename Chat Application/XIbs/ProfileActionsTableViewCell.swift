//
//  ProfileActionsTableViewCell.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 04/01/24.
//

import UIKit

class ProfileActionsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var actionLabel: UILabel!
    
    static let identifier = String(describing: ProfileActionsTableViewCell.self)
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
