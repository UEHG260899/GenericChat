//
//  ProfileViewController.swift
//  GenericChat
//
//  Created by Uriel Hernandez Gonzalez on 11/01/22.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ProfileViewController: UIViewController {

    
    @IBOutlet var tableView: UITableView!
    
    let data = ["Log out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableHeaderView = createTableHeader()
    }

    func createTableHeader() -> UIView? {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return nil}
        
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/\(fileName)"
        
        let headerView = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.width,
                                        height: 300))
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (view.width-150) / 2, y: 75, width: 150, height: 150))
        imageView.contentMode = .scaleToFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            switch result {
            case .success(let url):
                self?.downloadImag(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        }
        
        return headerView
    }
    
    func downloadImag(imageView: UIImageView, url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                return
            }
            
            //UI related stuff should go on main thread
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
            
        }.resume()
    }

}

//MARK: - Extensions
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            guard let strongSelf = self else {return}
            //FB Log out
            FBSDKLoginKit.LoginManager().logOut()
            
            //Google signout
            GIDSignIn.sharedInstance.signOut()
            
            do{
                try FirebaseAuth.Auth.auth().signOut()
                
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: true)
            }catch {
                print("Failed to log out")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
}
