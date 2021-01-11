//
//  ChatListViewController.swift
//  ChatappWithFireBase
//
//  Created by Koichi Muranaka on 2020/12/16.
//

import UIKit
import Firebase
import Nuke

class ChatListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    
    private let cellId = "cellId"
    //private var users = [User]()
    private var chatrooms = [ChatRoom]()
    private var chatRoomListner: ListenerRegistration?
    
    private var user: User? {
        didSet {
            navigationItem.title = user?.username
        }
    }
    
    @IBOutlet weak var chatListTableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
        confirmLoggedInUser()
        
        //ユーザーの情報を引っ張ってくるコード
        fetchChatroomsInfoFromFirestore()
        print("")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchLoginUserInfo()
        
    }
    
    
    func fetchChatroomsInfoFromFirestore() {
        chatRoomListner?.remove()
        chatrooms.removeAll()
        chatListTableView.reloadData()
        
        chatRoomListner = Firestore.firestore().collection("chatRooms")
            .addSnapshotListener { (snapshots, error) in
                //.getDocuments { (snapshots, error) in
                if error != nil {
                    print("chatRooms情報の取得に失敗しました。 \(error)")
                    return
                }
                
                snapshots?.documentChanges.forEach({ (documentChange) in
                    //新しい情報だけを受け取る
                    switch documentChange.type {
                    case .added:
                        self.handleAddedDocumentChange(documentChange: documentChange)
                    case .modified, .removed:
                        print("nothing to do")
                    }
            })
        }
    }

    
/*    private func fetchUserInfoFromFirebase() {
        Firestore.firestore().collection("users").getDocuments { (snapshots, error) in
            if error != nil {
                print("user情報の取得に失敗しました。\(error)")
                return
            }
            snapshots?.documents.forEach({ (snapshot) in
                let dic = snapshot.data()
                let user = User.init(dic: dic)
                
                self.users.append(user)
                self.chatListTableView.reloadData()
                
                self.users.forEach { (user) in
                    print("user.username: ", user.username)
                }
                
                //print("data: ", data)
            })
        }
    }
     
     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         fetchUserInfoFromFirebase()
     }
*/
    
    @objc private func tappedNavRightBarButton() {
        let storyboard = UIStoryboard.init(name: "UserList", bundle: nil)
        let userListViewController = storyboard.instantiateViewController(identifier: "UserListViewController")
        let nav = UINavigationController(rootViewController: userListViewController)
        self.present(nav, animated: true, completion: nil)
    }
    
    private func handleAddedDocumentChange(documentChange: DocumentChange) {
        let dic = documentChange.document.data()
        let chatroom = ChatRoom(dic: dic)
        chatroom.documentId = documentChange.document.documentID
        
        
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let isContain = chatroom.members.contains(uid)
        
        if !isContain { return }
        
        chatroom.members.forEach { (memberUid) in
            if memberUid != uid {
                Firestore.firestore().collection("users").document(memberUid).getDocument { (userSnapshot, error) in
                    if error != nil {
                        print("user情報の取得に失敗しました。 \(error)")
                        return
                    }
                    
                    
                    guard let dic = userSnapshot?.data() else { return }
                    let user = User(dic: dic)
                    user.uid = documentChange.document.documentID
                    chatroom.partnerUser = user
                    
                    guard let chatroomId = chatroom.documentId else { return }
                    let latestMessageId = chatroom.latestMessageId
                    
                    if latestMessageId == "" {
                        self.chatrooms.append(chatroom)
                        self.chatListTableView.reloadData()
                        return
                    }
                    
                    Firestore.firestore().collection("chatRooms").document(chatroom.documentId ?? "").collection("messages").document(latestMessageId).getDocument { (messageSnapshot, error
                ) in
                        if error != nil {
                            print("最新情報の取得に失敗しました。　\(error)")
                            return
                        }
                        
                        //snapshotのデータをmessageに変更
                        guard let dic = messageSnapshot?.data() else { return }
                        let message = Message(dic: dic)
                        chatroom.latestMessage = message
                        
                        
                        self.chatrooms.append(chatroom)
                        self.chatListTableView.reloadData()
                    }
                    
                }
            }
        }
    }
    
    private func setUpViews() {
        chatListTableView.tableFooterView = UIView()
        chatListTableView.delegate = self
        chatListTableView.dataSource = self
        
        navigationController?.navigationBar.barTintColor = .rgb(red: 39, green: 49, blue: 69)
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        
//        let storyboard = UIStoryboard(name: "signUp", bundle: nil)
//        let signUpViewController = storyboard.instantiateViewController(identifier: "SignUpViewController")as! SignUpViewController
//        signUpViewController.modalPresentationStyle = .fullScreen
//        self.present(signUpViewController, animated: true, completion: nil)
//
        
        let rightBarButton = UIBarButtonItem(title: "新規チャット開始", style: .plain, target: self, action: #selector(tappedNavRightBarButton))
        let logoutBarButton = UIBarButtonItem(title: "ログアウト", style: .plain, target: self, action: #selector(tappedLogOutButton))
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.leftBarButtonItem = logoutBarButton
        navigationItem.leftBarButtonItem?.tintColor = .white
    }
    
    @objc private func tappedLogOutButton () {
        do {
            try Auth.auth().signOut()
            pushLoginViewController()
        } catch {
            print("ログアウトに失敗しました。\(error)")
        }
    }
    
    private func confirmLoggedInUser() {
        if Auth.auth().currentUser?.uid == nil {
            pushLoginViewController()
        }
    }
    
    private func pushLoginViewController() {
        let storyboard = UIStoryboard(name: "signUp", bundle: nil)
        let signUpViewController = storyboard.instantiateViewController(identifier: "SignUpViewController")as! SignUpViewController
        let nav = UINavigationController(rootViewController: signUpViewController)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    private func fetchLoginUserInfo() {
        guard  let uid = Auth.auth().currentUser?.uid else {return }
        
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, error) in
            if error != nil {
                print("ユーザー情報の取得に失敗しました。　\(error)")
                return
            }
            guard let snapshot = snapshot, let dic = snapshot.data() else { return }
            let user = User(dic: dic)
            
            self.user =  user
            
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let  cell = chatListTableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! chatListTableViewCell
        //cell.user = users[indexPath.row]
        cell.chatroom = chatrooms[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("taped")
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboard.instantiateViewController(identifier: "ChatRoomViewController")as! ChatRoomViewController
        chatRoomViewController.user = user
        chatRoomViewController.chatroom = chatrooms[indexPath.row]
        navigationController?.pushViewController(chatRoomViewController, animated: true)
    }
}

   

    

class chatListTableViewCell: UITableViewCell {
    

    
    var chatroom: ChatRoom? {
        didSet {
            if chatroom != nil {
                partnerLabel.text = chatroom?.partnerUser?.username
                
                guard let url = URL(string: chatroom?.partnerUser?.profileImageUrl ?? "") else { return }
                Nuke.loadImage(with: url, into: userImageView)
                
                dateLabel.text = dateFormatterForTimeLabel(date: (chatroom?.latestMessage?.createdAt.dateValue()) ?? Date())
                latestMessageLabel.text = chatroom?.latestMessage?.message
            }
        }
    }
    
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var partnerLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var latestMessageLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    private func dateFormatterForTimeLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    
    }
}
