//
//  ChatRoomViewController.swift
//  ChatappWithFireBase
//
//  Created by Koichi Muranaka on 2020/12/17.
//

import UIKit
import Firebase

class ChatRoomViewController: UIViewController {

    var user: User?
    var chatroom: ChatRoom?

    private let cellId = "cellId"
    private var messages = [Message]()
    private let accessoryHeight: CGFloat = 100
    private let tableViewContentInset: UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
    private let tableViewIndicatorInset: UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
    private var safeAreaBottom: CGFloat {
        self.view.safeAreaInsets.bottom
    }

    private lazy var chatInputAccessoryView: ChatInputAccessoryView = {
        let view = ChatInputAccessoryView()
        view.frame = .init(x: 0, y: 0, width: view.frame.width, height: accessoryHeight)

        view.delegate = self
        return view
    }()

    @IBOutlet weak var chatRoomTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpNotification()
        setUpChatRoomTableView()

        fetchMessages()



    }
     func setUpNotification() {

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    private func setUpChatRoomTableView() {
        chatRoomTableView.delegate = self
        chatRoomTableView.dataSource = self

        chatRoomTableView.register(UINib(nibName: "ChatRoomTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
        chatRoomTableView.backgroundColor = .rgb(red: 118, green: 140, blue: 180)

//        let h : CGFloat = 80
//        chatBar = chatInputAccessoryView
//        chatBar.frame = CGRect(x: 0, y: view.bounds.height - h, width: view.bounds.width, height: h)
//        chatBar.backgroundColor = .rgb(red: 118, green: 140, blue: 180)
//
//        view.addSubview(chatBar)

        chatRoomTableView.contentInset = tableViewContentInset
        chatRoomTableView.scrollIndicatorInsets = tableViewIndicatorInset
        chatRoomTableView.keyboardDismissMode = .interactive
        chatRoomTableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)

    }



    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
        guard let userInfo = notification.userInfo else { return }

        if let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey]as AnyObject).cgRectValue {

            if keyboardFrame.height <= accessoryHeight { return }
            print("keyboardFrame: ", keyboardFrame)

            let top = keyboardFrame.height - safeAreaBottom
            var moveY = -(top - chatRoomTableView.contentOffset.y)
            if chatRoomTableView.contentOffset.y != -60 { moveY += 60 }
            print("chatRoomTableView.contentOffset.y: ", chatRoomTableView.contentOffset.y)
            let contentInset = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)

            chatRoomTableView.contentInset = contentInset
            chatRoomTableView.scrollIndicatorInsets = contentInset
            chatRoomTableView.contentOffset = CGPoint(x: 0, y: moveY)
        }
    }
    @objc func keyboardDidHide() {
        print("keyboardDidlHide")
            chatRoomTableView.contentInset = tableViewContentInset
            chatRoomTableView.scrollIndicatorInsets = tableViewIndicatorInset
        }

//    @objc func keyboardWillHide() {
//        print("keyboardWillHide")
//
//        chatRoomTableView.contentInset = tableViewContentInset
//        chatRoomTableView.scrollIndicatorInsets = tableViewIndicatorInset
//    }

    override var inputAccessoryView: UIView? {
        get {
            return chatInputAccessoryView
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    private func fetchMessages() {
        guard let chatroomDocId = chatroom?.documentId else { return }

    Firestore.firestore().collection("chatRooms").document(chatroomDocId).collection("messages").addSnapshotListener { (snapshots, error) in
            if error != nil {
                print("メッセージ情報の取得に失敗しました。\(error)")
                return
            }

            snapshots?.documentChanges.forEach({ (documentChange) in
                switch documentChange.type {
                case .added:
                    let dic = documentChange.document.data()
                    let message = Message(dic: dic)
                    message.partnerUser = self.chatroom?.partnerUser
                    self.messages.append(message)
                    //時間ごとに並べ替えるコード
                    self.messages.sort { (m1, m2) -> Bool in
                        let m1Date = m1.createdAt.dateValue()
                        let m2Date = m2.createdAt.dateValue()
                        return m1Date > m2Date
                    }

                    self.chatRoomTableView.reloadData()
//                    self.chatRoomTableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: true)

                case .modified, .removed:
                    print("nothing to do")
                }
            })
        }

    }


//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        chatRoomTableView.estimatedRowHeight = 20
//        return UITableView.automaticDimension
//
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return messages.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let  cell = chatRoomTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)as! ChatRoomTableViewCell
//        //cell.messageTextView.text = messages[indexPath.row]
//        cell.message = messages[indexPath.row]
//        return cell
//    }



}

extension ChatRoomViewController: ChatInputAccessoryViewDelegate {

    func tappedSendButton(text: String) {
        addMessageToFirestore(text: text)

    }

    private func addMessageToFirestore(text: String) {
        guard let chatroomDocId = chatroom?.documentId else { return }
        guard let name = user?.username else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        chatInputAccessoryView.removeText()
        let messageId = randomString(length: 20)

        let docData = [
            "name": name,
            "createdAt": Timestamp(),
            "uid": uid,
            "message":text
        ] as [String : Any]

            Firestore.firestore().collection("chatRooms").document(chatroomDocId)
                .collection("messages").document(messageId).setData(docData){ (error) in
            if error != nil {
                print("メッセージ情報の保存に失敗しました。\(error)")
                return
            }
            let latestMessageData = [
                "latestMessageId": messageId
            ]

            Firestore.firestore().collection("chatRooms").document(chatroomDocId).updateData(latestMessageData) { (error) in
                if error != nil {
                    print("最新メッセージの保存に失敗しました。\(error)")
                    return
                        }
                print("メッセージの保存に成功しました。")
                    }

        }
    }

    func randomString(length: Int) -> String {
            let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            let len = UInt32(letters.length)

            var randomString = ""
        for _ in 0..<length {
                let rand = arc4random_uniform(len)
                var nextChar = letters.character(at: Int(rand))
                randomString += NSString(characters: &nextChar, length: 1) as String
            }
            return randomString
    }

}

extension ChatRoomViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        chatRoomTableView.estimatedRowHeight = 20
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatRoomTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatRoomTableViewCell
        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
//        cell.messageTextView.text = messages[indexPath.row]
        cell.message = messages[indexPath.row]
        return cell
    }

}
