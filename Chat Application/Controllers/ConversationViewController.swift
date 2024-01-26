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
    
    private var conversations = [Conversation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        validateUser()
        startListeningForConversations()

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
        chatsTableView.register(UINib(nibName: ConversationTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: ConversationTableViewCell.identifier)
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
        let viewController = ChatViewController(with: email,with: name, with: nil)
        viewController.title = name
        viewController.isNewConversation = true 
        viewController.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func startListeningForConversations() {
        guard let email = AppDefaults.shared.email else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(with: email)
        DatabaseManager.shared.getAllConversations(with: safeEmail, completion:  { [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.chatsTableView.reloadData()
                }
            case .failure(let error):
                print(" error occured in fetching all convos \(error)")
            }
            
        })
        
    }
    
}

//MARK: TableView delegates

extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as? ConversationTableViewCell
        else {
            return UITableViewCell()
        }
        
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let model = conversations[indexPath.row]
        let viewController = ChatViewController(with: model.otherUserEmail,with: model.name, with: model.id)
        viewController.title = model.name
        viewController.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
 
