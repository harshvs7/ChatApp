//
//  LoginViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

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
    
    private func loginWithGoogle() async -> Bool {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("No client ID found in Firebase configuration")
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("There is no root view controller!")
            return false
        }
        
        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: self)
            
            let user = userAuthentication.user
            guard let idToken = user.idToken else { throw fatalError("ID token missing") }
            let accessToken = user.accessToken
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString,
                                                           accessToken: accessToken.tokenString)
            
            let result = try await Auth.auth().signIn(with: credential)
            let firebaseUser = result.user
            print("User \(firebaseUser.uid) signed in with email \(firebaseUser.email ?? "unknown")")
            return true
        }
        catch {
            print(error.localizedDescription)
            return false
        }
    }
    
}

//MARK: IBAction
extension LoginViewController {
    
    @IBAction func btnLoginTapped( _ sender: UIButton ) {
        login()
    }
    
    @IBAction func btnGoogleLoginTapped(_ sender: UIButton) {
        Task {
            if await loginWithGoogle() {
                dismiss(animated: true)
            }
        }
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
