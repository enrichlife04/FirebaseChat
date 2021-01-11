//
//  PlotoTypeUserListViewController.swift
//  ChatappWithFireBase
//
//  Created by Koichi Muranaka on 2020/12/30.
//

import UIKit
import Firebase
import Nuke

class UserListViewController : UIViewController {
    
    private let cellId = "cellId"
    private var users = [User]()
    private var selectedUser: User?
    
    @IBOutlet weak var userListTableView: UITableView!
    @IBOutlet weak var startChatButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userListTableView.tableFooterView = UIView()
        userListTableView.delegate = self
        userListTableView.dataSource = self
        startChatButton.layer.cornerRadius = startChatButton.bounds.height / 2.0
        startChatButton.isEnabled = false
        startChatButton.addTarget(self, action: #selector(tappedStartChatButton), for: .touchUpInside)
        navigationController?.navigationBar.barTintColor = .rgb(red: 39, green: 49, blue: 69)
        //userListTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        
        fetchUserInfoFromFirebase()
    }
    
    @objc func tappedStartChatButton() {
        print("tappedStartChatButton")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let partnerUid = self.selectedUser?.uid else { return }
        let members = [uid, partnerUid]

        let docData = [
            "members": members,
            "latestMessageId": "",
            "createdAt": Timestamp()
        ] as [String : Any]
        
        Firestore.firestore().collection("chatRooms").addDocument(data: docData) { (error) in
            if error != nil {
                print("chatRoom情報の保存に失敗しました。\(error)")
            }
            
            self.dismiss(animated: true, completion: nil)
            print("chatRoom情報の保存に成功しました。")
        }
    }
    
    private func fetchUserInfoFromFirebase() {
        Firestore.firestore().collection("users").getDocuments { (snapshots, error) in
            if error != nil {
                print("user情報の取得に失敗しました。\(error)")
                return
            }
            snapshots?.documents.forEach({ (snapshot) in
                let dic = snapshot.data()
                let user = User.init(dic: dic)
                user.uid = snapshot.documentID
                
                guard let uid = Auth.auth().currentUser?.uid else { return }
                
                if uid == snapshot.documentID {
                    return
                }
                
                self.users.append(user)
                self.userListTableView.reloadData()
                
                /*self.users.forEach { (user) in
                    print("user.username: ", user.username)
                }*/
                //print("data: ", data)
            })
        }
    }
}
extension UserListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = userListTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserListTableViewCell
        cell.user = users[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //選択されたセルの情報を持ってくるコード
        startChatButton.isEnabled = true
        let user = users[indexPath.row]
        self.selectedUser = user
        
        
    }
    
    
}

class UserListTableViewCell: UITableViewCell {
    
    var user: User? {
        didSet{
            usernameLabel.text = user?.username
            
            if let url = URL(string: user?.profileImageUrl ?? "" ) {
                Nuke.loadImage(with: url, into: userImageView)
            }
        }
    }
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    
    /*override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
    }*/
    override func awakeFromNib() {
           super.awakeFromNib()
        userImageView.layer.cornerRadius = userImageView.bounds.height / 2.0
           
       }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected , animated: animated)
    }
}


