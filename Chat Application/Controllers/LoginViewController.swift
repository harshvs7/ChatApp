//
//  LoginViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpUI()
    }
    
}

//MARK: Helper functions
extension LoginViewController {
    
    private func setUpUI(){
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        self.title = "Log In"
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                                 style: .done,
                                                                 target: self,
                                                                 action: #selector(btnRegisterTapped))
    }
    
    @objc private func btnRegisterTapped() {
        let viewController = RegisterViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func login() {
        guard let email = emailTextField.text, let password = passwordTextField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            self.showAlert(with: "Error", with: "Please enter valid email and password", with: "Dismiss")
            return
        }
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            guard let _ = authResult, error == nil else {
                strongSelf.showAlert(with: "Error", with: error?.localizedDescription ?? "", with: "Dismiss")
                return
            }
            strongSelf.navigationController?.dismiss(animated: true)
        })
    }
    
}

//MARK: IBAction
extension LoginViewController {
    
    @IBAction func btnLoginTapped( _ sender: UIButton ) {
        login()
    }
}

//MARK: TextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        }
        if textField == passwordTextField {
            passwordTextField.resignFirstResponder()
            self.login()
        }
        return true
    }
    
    
}
