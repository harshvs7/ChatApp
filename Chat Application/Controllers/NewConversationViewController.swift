//
//  NewConversationViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    @IBOutlet weak var searchUsers: UISearchBar!
    @IBOutlet weak var userTableView: UITableView!
    @IBOutlet weak var noResultLabel: UILabel!
    
    private let spinner = JGProgressHUD(style: .dark)
    private var users = [[String: String]]()
    private var results = [[String: String]]()
    private var hasFetched = false
    public var completion: (([String:String] ) -> (Void))?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

//MARK: helper functions
extension NewConversationViewController {
    private func setupUI() {
        userTableView.delegate = self
        userTableView.dataSource = self
        userTableView.register(UINib(nibName: SingleChatTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: SingleChatTableViewCell.identifier)
        navigationController?.navigationBar.topItem?.titleView = searchUsers
        searchUsers.becomeFirstResponder()
    }
    
    private func searchUsers(with query: String) {
        if hasFetched {
            self.filterUser(with: query)
        } else {
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let userCollection):
                    strongSelf.users = userCollection
                    strongSelf.hasFetched = true
                    strongSelf.filterUser(with: query)
                    print("Aagya users/.......\(strongSelf.users)")
                case .failure(let error):
                    print("Error occured while fetching users .... \(error)")
                }
            })
        }
    }
    private func filterUser(with term: String) {
        guard hasFetched else { return }
        self.spinner.dismiss()
        let results: [[String: String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        self.results = results
        print("Aagya resultttt/.......\(results)")
        updateUI()
    }
    private func updateUI() {
        if results.isEmpty {
            noResultLabel.isHidden = false
            userTableView.isHidden = true
        } else {
            noResultLabel.isHidden = true
            userTableView.isHidden = false
            userTableView.reloadData()
        }
    }
}

//MARK: SearchBarDelegate
extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        self.results.removeAll()
        self.spinner.show(in: view)
        self.searchUsers(with: text)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true)
    }
}

//MARK: TableView delegates
extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SingleChatTableViewCell.identifier) as? SingleChatTableViewCell else {
            return UITableViewCell()
        }
        cell.ChatName.text = results[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUser = results[indexPath.row]
         dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUser)
        })
    }
}
