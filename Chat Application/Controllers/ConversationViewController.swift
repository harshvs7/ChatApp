//
//  ConversationViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import UIKit
import FirebaseAuth

class ConversationViewController: UIViewController {
    
    @IBOutlet weak var chatsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        validateUser()
    }
    
    
}

//MARK: helper functions
extension ConversationViewController {
    private func validateUser() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let viewController = LoginViewController()
            let nav = UINavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .fullScreen
            present(nav,animated: true)
        }
    }
    
    private func setupUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapCompose))
        chatsTableView.delegate = self
        chatsTableView.dataSource = self
        chatsTableView.register(UINib(nibName: SingleChatTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: SingleChatTableViewCell.identifier)
    }
    
    @objc private func didTapCompose() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            self?.createNewConversation(with: result)
        }
        let viewController = UINavigationController(rootViewController: vc)
        present(viewController, animated: true)
    }
    
    private func createNewConversation(with result: [String: String]) {
        guard let name = result["name"],
              let email = result["safe_email"] else {
            
                return
        }
        let viewController = ChatViewController(with: email)
        viewController.title = name
        viewController.isNewConversation = true 
        viewController.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

//MARK: TableView delegates

extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SingleChatTableViewCell.identifier, for: indexPath) as? SingleChatTableViewCell 
        else {
            return UITableViewCell()
        }
        
        cell.ChatName.text = "Chat 1"
        return cell
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: false)
//        let viewController = ChatViewController()
//        self.navigationController?.pushViewController(viewController, animated: true)
//    }
}
