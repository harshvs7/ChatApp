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
import JGProgressHUD

class LoginViewController: UIViewController {
    
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
}

//MARK: Helper functions
extension LoginViewController {
    
    private func setUpUI(){
        emailTextField.delegate = self
        passwordTextField.delegate = self
        title = "Log In"
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                                 style: .done,
                                                                 target: self,
                                                                 action: #selector(btnRegisterTapped))
    }
    
    @objc private func btnRegisterTapped() {
        let viewController = RegisterViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func login() {
        
        guard let email = emailTextField.text, let password = passwordTextField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            showAlert(with: "Error", with: "Please enter valid email and password", with: "Dismiss")
            return
        }
        spinner.show(in: view)
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let _ = authResult, error == nil else {
                strongSelf.showAlert(with: "Error", with: error?.localizedDescription ?? "", with: "Dismiss")
                return
            }
            
            let safeEmail = DatabaseManager.safeEmail(with: email)
            
            DatabaseManager.shared.getInfoFor(with: safeEmail, completion: { result in
                switch result {
                case .success(let value):
                    guard let userData = value as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    AppDefaults.shared.name = "\(firstName) \(lastName)"
                    AppDefaults.shared.email = email
                case .failure(let error):
                    print("failed to fetch the error \(error)")
                }
            })
            
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
            
            _ = try await Auth.auth().signIn(with: credential)
            guard let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName,
                  let email = user.profile?.email else {
                
                print("no user info")
                return true
            }
            AppDefaults.shared.email = email
            AppDefaults.shared.name = "\(firstName) \(lastName)"
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            guard let hasImage = user.profile?.hasImage else { return }
                            if  hasImage {
                                guard let imageUrl = user.profile?.imageURL(withDimension: 200) else { return }
                                
                                URLSession.shared.dataTask(with: imageUrl,completionHandler: { data, _, _ in
                                    guard let data = data else { return }
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: chatUser.profilePictureFileName, completion: { result in
                                        switch result {
                                            
                                        case .success(let downloadURL):
                                            AppDefaults.shared.profilePicture = downloadURL
                                            print( "\(downloadURL)")
                                            
                                        case .failure(let error):
                                            print("error in downloading \(error)")
                                        }
                                    })
                                }).resume()
                                
                            }
                        }
                    })
                }
            })
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
            login()
        }
        return true
    }
    
    
}
