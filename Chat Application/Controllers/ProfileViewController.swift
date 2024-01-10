//
//  ProfileViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import UIKit
import FirebaseAuth
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var actionTableView: UITableView!
    
    private var actions = ["Log out"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
    private func setUpUI() {
        actionTableView.delegate = self
        actionTableView.dataSource = self
        actionTableView.register(UINib(nibName: ProfileActionsTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: ProfileActionsTableViewCell.identifier)
    }
}

//MARK: TableView delegate methods
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileActionsTableViewCell.identifier, for: indexPath) as? ProfileActionsTableViewCell else { return UITableViewCell() }
        
        cell.actionLabel.text = actions[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        self.showAlertTwoButton(with: "Log out", with: "Do you want to logout?", with: "Cancel", with: "Yes", completion: { [weak self] logOut in
            guard let strongSelf = self else { return }
            if logOut { 
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    let viewController = LoginViewController()
                    let nav = UINavigationController(rootViewController: viewController)
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav,animated: true)
                } catch {
                    print("error")
                }
            } else {
                strongSelf.dismiss(animated: true)
            }
            
        })
    }
    
}
