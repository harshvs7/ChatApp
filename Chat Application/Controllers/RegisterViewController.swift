//
//  RegisterViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import UIKit
import PhotosUI
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var profileImage: UIImageView!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
}

//MARK: helper function
extension RegisterViewController {
    
    private func setUpUI() {
        self.title = "Register User"
        self.firstNameTextField.delegate = self
        self.lastNameTextField.delegate = self
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        self.profileImage.image = UIImage(systemName: "person.circle")
        self.profileImage.tintColor = UIColor.lightGray
        self.profileImage.makeCircleRound()
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImage.addGestureRecognizer(tap)
    }
    
    private func registerUser(){
        passwordTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        firstNameTextField.resignFirstResponder()
        
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty, password.count >= 6
        else {
            self.showAlert(with: "Error", with: "Please add the valid information", with: "Dismiss")
            return
        }
        
        spinner.show(in: view)
        
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exists in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard !exists else {
                strongSelf.showAlert(with: "Error", with: "User already registered", with: "Pop")
                return
            }
            
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { [weak self] authResult, error in
                guard let strongSelf = self else { return }
                guard authResult != nil, error == nil else {
                    strongSelf.showAlert(with: "Error", with: error?.localizedDescription ?? "", with: "Dismiss")
                    return
                }
                let user = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                DatabaseManager.shared.insertUser(with: user, completion: { success in
                    if success {
                        //upload image
                        guard let image = strongSelf.profileImage.image, let data = image.pngData() else {
                            return
                        }
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: user.profilePictureFileName, completion: { result in
                            switch result {
                                
                            case .success(let downloadURL):
                                UserDefaults.standard.setValue(downloadURL, forKey: "profile_picture_url")
                                AppDefaults.shared.profilePicture = downloadURL
                                AppDefaults.shared.email = email
                                AppDefaults.shared.name = firstName + lastName
                                print( "\(downloadURL)")
                                
                            case .failure(let error):
                                print("error in downloading \(error)")
                            }
                        })
                    }
                })
                
                strongSelf.navigationController?.dismiss(animated: true)
            })
            
        })
        
        
    }
    
    @objc private func profileImageTapped() {
        presentPhotoActionSheet()
    }
}

//MARK: IBActions
extension RegisterViewController {
    
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        registerUser()
    }
}

//MARK: TextFieldDelegate
extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn( _ textField: UITextField) -> Bool {
        if textField == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        } else if textField == lastNameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            passwordTextField.resignFirstResponder()
            self.registerUser()
        }
        
        return true
    }
    
}

//MARK: ProfileImage Picker Delegates
extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    private func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to choose your profile photo",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil ))
        
        actionSheet.addAction(UIAlertAction(title: "Open Camera",
                                            style: .default,
                                            handler: { [weak self] _ in
            
            self?.openCamera()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Open Photos",
                                            style: .default,
                                            handler: { [weak self] _ in
            
            self?.openPhotoLibrary()
            
        }))
        present(actionSheet,animated: true)
    }
    
    private func openCamera() {
        
        let cameraVC = UIImagePickerController()
        cameraVC.delegate = self
        cameraVC.sourceType = .camera
        cameraVC.allowsEditing = true
        
        present(cameraVC,animated: true)
    }
    
    private func openPhotoLibrary() {
        
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let photoVC = PHPickerViewController(configuration: configuration)
        photoVC.delegate = self
        
        present(photoVC,animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first?.itemProvider else { return }
        
        if item.canLoadObject(ofClass: UIImage.self) {
            item.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                if let error {
                    self?.showAlert(with: "Error", with: error.localizedDescription, with: "Dismiss")
                }
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self?.profileImage.image = image
                    }
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.profileImage.image = selectedImage
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
}
