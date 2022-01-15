//
//  LoginViewController.swift
//  GenericChat
//
//  Created by Uriel Hernandez Gonzalez on 11/01/22.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Login"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(onClickedLogin), for: .touchUpInside)
        
        emailField.delegate = self
        passWordField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passWordField)
        scrollView.addSubview(loginButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width  - size) / 2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        passWordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passWordField.bottom + 10, width: scrollView.width - 60, height: 52)
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
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let strongSelf = self else {return}
            guard let _ = result, error == nil else {
                print("Error log in user")
                return
            }
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
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
