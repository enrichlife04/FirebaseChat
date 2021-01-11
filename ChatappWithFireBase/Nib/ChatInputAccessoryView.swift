//
//  ChatInputAccessoryView.swift
//  ChatappWithFireBase
//
//  Created by 雪上智紀 on 2020/12/18.
//

import UIKit

protocol ChatInputAccessoryViewDelegate: class {
    func tappedSendButton(text: String)
}
class ChatInputAccessoryView: UIView {
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatTextView: UITextView!
    @IBAction func tappedSendButton(_ sender: Any) {
        guard  let text = chatTextView.text else { return }
        delegate?.tappedSendButton(text: text)
    }
    
    weak var delegate: ChatInputAccessoryViewDelegate?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        nibInit()
        setUpViews()
        autoresizingMask = .flexibleHeight
    }
    
    
    
    private func setUpViews() {
        chatTextView.layer.cornerRadius = 15
        chatTextView.layer.borderColor = UIColor.rgb(red: 230, green: 230, blue: 230).cgColor
        chatTextView.layer.borderWidth = 1
        
        sendButton.layer.cornerRadius = 15
        sendButton.imageView?.contentMode = .scaleAspectFill
        sendButton.contentHorizontalAlignment = .fill
        sendButton.contentVerticalAlignment = .fill
        sendButton.isEnabled = false
        
        chatTextView.text = ""
        chatTextView.delegate = self
        

    }
    
    func removeText() {
        chatTextView.text = ""
        sendButton.isEnabled = false
    }
    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    private func nibInit() {
        let nib = UINib(nibName: "ChatInputAccessoryView", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return
        }
        
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        

}

extension ChatInputAccessoryView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        //print("textView.text: ", textView.text)
        if textView.text.isEmpty {
            sendButton.isEnabled = false
        } else {
            sendButton.isEnabled = true
        }
    }
}

