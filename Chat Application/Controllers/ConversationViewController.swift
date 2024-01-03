//
//  ConversationViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import UIKit
import FirebaseAuth

class ConversationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        validateUser()
    }

    private func validateUser() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let viewController = LoginViewController()
            let nav = UINavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .fullScreen
            present(nav,animated: true)
        }
    }
}
