//
//  NewConversationViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import UIKit

class NewConversationViewController: UIViewController {
    
    @IBOutlet weak var searchUsers: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

//MARK: helper functions
extension NewConversationViewController {
    private func setupUI() {
        navigationController?.navigationBar.topItem?.titleView = searchUsers
        searchUsers.becomeFirstResponder()
    }
}

//MARK: SearchBarDelegate
extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print(searchBar.text)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true)
    }
}
