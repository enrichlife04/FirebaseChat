//
//  SignUpViewController.swift
//  ChatappWithFireBase
//
//  Created by Koichi Muranaka on 2020/12/27.
//

import UIKit
import Firebase
//import FirebaseFirestore
//import FirebaseAuth
import PKHUD


class SignUpViewController: UIViewController {
    
    
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var alreadyHaveAccountButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super .viewDidLoad()
        setupViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //ナビゲーションバーを隠すコード
        navigationController?.navigationBar.isHidden = true
    }
    
    private func setupViews() {
        profileImageButton.layer.cornerRadius = profileImageButton.bounds.width / 2.0
        profileImageButton.layer.borderWidth = 1
        profileImageButton.layer.borderColor = UIColor.rgb(red: 240, green: 240, blue: 240).cgColor
        
        registerButton.layer.cornerRadius = 12
        
        profileImageButton.addTarget(self, action: #selector(tappedProfileImageButton), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(tappedRegisterButton), for: .touchUpInside)
        alreadyHaveAccountButton.addTarget(self, action: #selector(tappedAlreadyHaveAccountButton), for: .touchUpInside)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.delegate = self
        
        registerButton.isEnabled = false
        registerButton.backgroundColor = UIColor.rgb(red: 100, green: 100, blue: 100)
        
    }
    
    @objc private func tappedAlreadyHaveAccountButton() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(identifier: "LoginViewController")
        self.navigationController?.pushViewController(loginViewController, animated: true)
    }
    
    @objc private func tappedProfileImageButton() {
        //print("tappedProfileImageButton")
        let imagePickerControler = UIImagePickerController()
        imagePickerControler.delegate = self
        imagePickerControler.allowsEditing = true
        
        self.present(imagePickerControler, animated: true, completion: nil)
        
    }
    
    @objc private func tappedRegisterButton() {
        let image = profileImageButton.imageView?.image ?? UIImage(named: "手に×ガール")
        guard let uploadImage = image?.jpegData(compressionQuality: 0.3) else { return }
        
        HUD.show(.progress)
        
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_Image").child(fileName)
        
        storageRef.putData(uploadImage, metadata: nil) { (metadata, error) in
            if error != nil {
                
                HUD.hide()
                print("firestorageへの情報の保存に失敗しました。\(error)")
                return
            }
            //print("firestorageへの情報の保存に成功しました。")
            storageRef.downloadURL { (url, error) in
                if error != nil {
                    HUD.hide()
                    print("firestorageからのダウンロードに失敗しました。\(error)")
                    return
                }
                guard let urlString = url?.absoluteString else { return }
                //print("urlString: ", urlString)
                self.createUserToFirestore(profileImageUrl: urlString)
            }
        }
        
    }
    
    private func createUserToFirestore(profileImageUrl: String) {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if error != nil {
                HUD.hide()
                print("認証情報の保存に失敗しました。\(error)")
                return
            }
            
            //print("認証情報の保存に成功しました")
            
            guard let uid = result?.user.uid else { return }
            guard let username = self.usernameTextField.text else { return }
            let docData = [
                "email": email,
                "username": username,
                "createdAt": Timestamp(),
                "profileImageUrl": profileImageUrl
            ] as [String : Any]
            
            Firestore.firestore().collection("users").document(uid).setData(docData) { (error) in
                if error != nil {
                    HUD.hide()
                    print("Firestoreへの保存に失敗しました。\(error)")
                    return
                }
                HUD.hide()
                
                print("Firestoreへ情報の保存が成功しました。")
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

extension SignUpViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        //print("textField.text: ", textField.text)
        let emailIsEmpty = emailTextField.text?.isEmpty ?? false
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? false
        let usernameIsEmpty = usernameTextField.text?.isEmpty ?? false
        
        if emailIsEmpty || passwordIsEmpty || usernameIsEmpty {
            registerButton.isEnabled = false
            registerButton.backgroundColor = UIColor.rgb(red: 100, green: 100, blue: 100)
        } else {
            registerButton.isEnabled = true
            registerButton.backgroundColor = UIColor.rgb(red: 0, green: 185, blue: 0)
        }
    }
}

extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let edditImage = info[.editedImage] as? UIImage {
            profileImageButton.setImage(edditImage.withRenderingMode(.alwaysOriginal), for: .normal)
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        profileImageButton.setTitle("", for: .normal)
        profileImageButton.imageView?.contentMode = .scaleAspectFill
        profileImageButton.contentHorizontalAlignment = .fill
        profileImageButton.contentVerticalAlignment = .fill
        profileImageButton.clipsToBounds = true
        
        dismiss(animated: true, completion: nil)
        
    }
    
}
