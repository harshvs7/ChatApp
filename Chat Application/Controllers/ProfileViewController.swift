//
//  ProfileViewController.swift
//  Chat Application
//
//  Created by Harshvardhan Sharma on 28/12/23.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import JGProgressHUD

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var actionTableView: UITableView!
    
    private var actions = ["Log out"]
    private let spinner = JGProgressHUD(style: .dark)

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        actionTableView.reloadData()
    }
    
    private func setUpUI() {
        actionTableView.delegate = self
        actionTableView.dataSource = self
        actionTableView.register(UINib(nibName: ProfileActionsTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: ProfileActionsTableViewCell.identifier)
        actionTableView.register(UINib(nibName: ProfileImageHeaderView.identifier, bundle: nil), forHeaderFooterViewReuseIdentifier: ProfileImageHeaderView.identifier)
    }
}

//MARK: helper functions
extension ProfileViewController {
    
    private func downloadProfileImage( with url: URL, with imageView: UIImageView) {
        URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
                self.spinner.dismiss()
            }
        }).resume()
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
                    strongSelf.present(nav,animated: true,completion: {
                        AppDefaults.shared.email = nil
                        AppDefaults.shared.profilePicture = nil
                        AppDefaults.shared.name = nil
                    })
                    
                } catch {
                    print("error")
                }
            } else {
                strongSelf.dismiss(animated: true)
            }
            
        })
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: ProfileImageHeaderView.identifier) as? ProfileImageHeaderView
        else {
            return UIView()
        }
        guard let email = AppDefaults.shared.email else { return UIView() }
         let safeEmail = DatabaseManager.safeEmail(with: email)
        let path = "images/" + safeEmail + "_profile_picture.png"
        self.spinner.show(in: view)
        StorageManager.shared.downloadURL(with: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                self?.downloadProfileImage(with: url, with: header.profileImageView)
            case .failure(let error):
                print("error has occured while downloading image ......\(error)")
            }
            
        })
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let email = AppDefaults.shared.email else { return 0 }
        return 150
    }
}

