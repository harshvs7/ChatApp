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
    @IBOutlet weak var noResultFoundLabel: UILabel!
    private var conversations = [Conversation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        validateUser()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startListeningForConversations()
        setupUI()
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
            guard let strongSelf = self else { return }
            
            let conversations = strongSelf.conversations
            if let targetConversation = conversations.first(where: {
                
                $0.otherUserEmail == DatabaseManager.safeEmail(with: result.email)
            }) {
                let viewController = ChatViewController(with: targetConversation.otherUserEmail,
                                                        with: targetConversation.name,
                                                        with: targetConversation.id)
                viewController.title = targetConversation.name
                viewController.isNewConversation = false
                viewController.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(viewController, animated: true)
            } else {
                strongSelf.createNewConversation(with: result)

            }
             
        }
        let viewController = UINavigationController(rootViewController: vc)
        present(viewController, animated: true)
    }
    
    private func createNewConversation(with result: SearchUserResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(with: result.email)
        
        
        DatabaseManager.shared.conversationExists(targetRecipientEmail: email, completion: { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let id):
                let viewController = ChatViewController(with: email,with: name, with: id)
                viewController.title = name
                viewController.isNewConversation = false
                viewController.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(viewController, animated: true)
            case .failure(_):
                let viewController = ChatViewController(with: email,with: name, with: nil)
                viewController.title = name
                viewController.isNewConversation = true
                viewController.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(viewController, animated: true)
            }
        })
        
        
        
        
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
                    self?.chatsTableView.isHidden = true
                    self?.noResultFoundLabel.isHidden = false
                    return
                }
                self?.conversations = conversations
                self?.chatsTableView.isHidden = false
                self?.noResultFoundLabel.isHidden = true
                DispatchQueue.main.async {
                    self?.chatsTableView.reloadData()
                }
            case .failure(let error):
                self?.chatsTableView.isHidden = true
                self?.noResultFoundLabel.isHidden = false
                print(" error occured in fetching all convos \(error)")
            }
            
        })
        
    }
    
    private func openConversation(model: Conversation) {
        let viewController = ChatViewController(with: model.otherUserEmail,with: model.name, with: model.id)
        viewController.title = model.name
        viewController.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(viewController, animated: true)
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
        openConversation(model: model)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let conversationId = conversations[indexPath.row].id
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _,_, completionhandler in            
            DatabaseManager.shared.deletingConversation(conversationID: conversationId, completion: { success in
                if !success {
                    if indexPath.row < self?.conversations.count ?? 0 {
                        self?.conversations.remove(at: indexPath.row)
                    }
                }
                completionhandler(success)
            })
        }
        
        deleteAction.backgroundColor = .red
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return configuration
    }
}

