//
//  LoginViewController.swift
//  GenericChat
//
//  Created by Uriel Hernandez Gonzalez on 11/01/22.
//

import UIKit
import Firebase
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor =  .white
        return field
    }()
    
    private let passWordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor =  .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let fbButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email","public_profile"]
        return button
    }()
    
    private let googleBtn: GIDSignInButton = {
        let button = GIDSignInButton()
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Login"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(onClickedLogin), for: .touchUpInside)
        
        emailField.delegate = self
        passWordField.delegate = self
        
        fbButton.delegate = self
        googleBtn.addTarget(self, action: #selector(onClickedLoginGoogle), for: .touchUpInside)
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passWordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(fbButton)
        scrollView.addSubview(googleBtn)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width  - size) / 2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        passWordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passWordField.bottom + 10, width: scrollView.width - 60, height: 52)
        fbButton.frame = CGRect(x: 30, y: loginButton.bottom + 10, width: scrollView.width - 60, height: 52)
        googleBtn.frame = CGRect(x: 30, y: fbButton.bottom + 10, width: scrollView.width - 60, height: 52)
    }
    
    
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops", message: "Please enter all the information to login", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    @objc func onClickedLogin() {
        
        emailField.resignFirstResponder()
        passWordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passWordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                  alertUserLoginError()
                  return
              }
        
        spinner.show(in: view)
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let strongSelf = self else {return}
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let _ = result, error == nil else {
                print("Error log in user")
                return
            }
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @objc func onClickedLoginGoogle() {
        guard let clientId = FirebaseApp.app()?.options.clientID else {return}
        
        let config = GIDConfiguration(clientID: clientId)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [weak self] user, error in
            guard let strongSelf = self else {return}
            guard error == nil else {
                if let error = error {
                    print("Failed to sign in woth Google: \(error)")
                }
                return
            }
            
            
            let email = user?.profile?.email
            let firstName = user?.profile?.givenName
            let lastName = user?.profile?.familyName
            
            DatabaseManager.shared.userExists(with: email!) { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName!, lastName: lastName!, emailAddress: email!)
                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                        if success {
                            
                            if user!.profile!.hasImage {
                                guard let url = user!.profile?.imageURL(withDimension: 200) else {return}
                                
                                
                                URLSession.shared.dataTask(with: url) { data, _, error in
                                    
                                    guard let data = data else {return}
                                    
                                    let chatUser = ChatAppUser(firstName: firstName!, lastName: lastName!, emailAddress: email!)
                                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                                        if success {
                                            let fileName = chatUser.profilePictureFileName
                                            
                                            StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                                switch result {
                                                case .success(let downLoadUrl):
                                                    UserDefaults.standard.set(downLoadUrl, forKey: "profile_picture_url")
                                                    print(downLoadUrl)
                                                case .failure(let error):
                                                    print("Storage manager error: \(error)")
                                                }
                                            }
                                        }
                                    }
                                    
                                }.resume()
                                
                                
                            }
                            
                        }
                    }
                }
            }
            
            guard let authentication = user?.authentication, let idToken = authentication.idToken else {return}
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) { result, error in
                guard result != nil, error == nil else {
                    print("Failed to login with the google credential")
                    return
                }
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
            
        }
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


//MARK: - Extensions

extension LoginViewController: UITextFieldDelegate {
    
    // Called when user hits return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passWordField.becomeFirstResponder()
        }else if textField == passWordField {
            onClickedLogin()
        }
        
        return true
    }
    
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("Failed to login with Facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start { connection, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make graph request")
                return
            }
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String : Any],
                  let data = picture["data"] as? [String : Any],
                  let pictureUrl = data["url"] as? String else {
                      print("Failed to get user data from Facebook")
                      return
                  }
            
            
            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists {
                    
                    
                    guard let url = URL(string: pictureUrl) else {return}
                    
                    URLSession.shared.dataTask(with: url) { data, _, error in
                        guard let data = data else {return}
                        
                        let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                        DatabaseManager.shared.insertUser(with: chatUser) { success in
                            if success {
                                let fileName = chatUser.profilePictureFileName
                                
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                    switch result {
                                    case .success(let downLoadUrl):
                                        UserDefaults.standard.set(downLoadUrl, forKey: "profile_picture_url")
                                        print(downLoadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                }
                            }
                        }
                    }.resume()
                    
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] result, error in
                guard let strongSelf = self else {return}
                guard result != nil, error == nil else {
                    print("MFA may be needed")
                    return
                }
                print("Successful")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
}
