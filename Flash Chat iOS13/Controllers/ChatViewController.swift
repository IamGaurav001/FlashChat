import UIKit
import SwiftUI 
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages : [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        loadMessages()
    }
    
    func loadMessages() {
        
        
        db.collection(K.FStore.collectionName)
            .order(by:K.FStore.dateField)
            .addSnapshotListener{
            (querySnapshot, error) in
            
            self.messages = []
            if let e = error {
                           print (e)
            }else {
                if let snapShortDocuments = querySnapshot?.documents {
                    for doc in snapShortDocuments {
                        let data = doc.data()
                        if let messageSender =
                            data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String  {
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
        
        @IBAction func sendPressed(_ sender: UIButton) {
            if let messageBody = messageTextfield.text,
               let messageSender = Auth.auth().currentUser?.email {
                db.collection(K.FStore.collectionName).addDocument(data:  [K.FStore.senderField : messageSender,K.FStore.bodyField :messageBody , K.FStore.dateField : Date().timeIntervalSince1970]) { (error) in
                    if let e = error {
                        print (e)
                    }else{
                        print ("Done")
                        DispatchQueue.main.async {
                            self.messageTextfield.text = ""
                        }
                    }
                }
            }
        }
        
        @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                navigationController?.popToRootViewController(animated: true)
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
            }
        }
    }
    
    extension ChatViewController : UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return messages.count
        }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let message = messages[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier:  K.cellIdentifier, for: indexPath)
            as! MessageCell
            cell.label.text = message.body
            // message from current Sender
            if message .sender == Auth.auth().currentUser?.email {
                cell.leftImageView.isHidden = true
                cell.rightimageView.isHidden = false
                cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
                //cell.messageBubble.interactions.description.propertyList()
                cell.label.textColor = UIColor(named : K.BrandColors.purple)
            }
            // message from another sender
            else {
                cell.leftImageView.isHidden = false
                cell.rightimageView.isHidden = true 
            }
            
            return cell
        }
    }
 

