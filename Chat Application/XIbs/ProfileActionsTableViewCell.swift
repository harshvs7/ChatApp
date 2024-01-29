//
//  ProfileActionsTableViewCell.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 04/01/24.
//

import UIKit


enum ProfileTableType {
    case info
    case logout
}

struct ProfileTableModel {
    let viewModel: ProfileTableType
    let title: String
    let handler: (() -> Void)?
}


class ProfileActionsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var actionLabel: UILabel!
    
    static let identifier = String(describing: ProfileActionsTableViewCell.self)
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public func setUp(model: ProfileTableModel) {
        actionLabel.text = model.title
        switch model.viewModel {
        case .info:
            actionLabel.textAlignment = .left
            actionLabel.textColor = .link
        case .logout:
            actionLabel.textAlignment = .center
            actionLabel.textColor = .red
        }
    }
    
}
