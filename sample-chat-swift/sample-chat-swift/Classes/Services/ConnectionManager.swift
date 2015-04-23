//
//  ConnectionManager.swift
//  sample-chat-swift
//
//  Created by Anton Sokolchenko on 3/31/15.
//  Copyright (c) 2015 quickblox. All rights reserved.
//

import UIKit

class ConnectionManager: NSObject, QBChatDelegate {
    static let instance = ConnectionManager()
    
    private var presenceTimer:NSTimer!
    private var chatLoginCompletion:((Bool, String?) -> Void)!
    var dialogs:[QBChatDialog]?
    var dialogsUsers:[QBUUser]?
    var messagesIDsToDelete: DynamicArray<String> = DynamicArray(Array())
    let messagesBond = ArrayBond<String>()
    var currentUser:QBUUser?
    
    let usersDataSource:UsersDataSource = UsersDataSource()
    let privacyManager:PrivacyManager = PrivacyManager()
    
     private override init() {
        super.init()
        QBChat.instance().addDelegate(self)
        self.startObservingMessagesToDelete()
    }
    
    func logInWithUser(user: QBUUser, completion: (success: Bool, errorMessage: String?) -> Void){
        var params = QBSessionParameters()
        params.userLogin = user.login
        params.userPassword = user.password
        
        QBRequest.createSessionWithExtendedParameters(params, successBlock: { [weak self ] (response: QBResponse!, session: QBASession!) -> Void in
            if let strongSelf = self{
                var conm = ConnectionManager.instance
                
                conm.currentUser = QBUUser()
                conm.currentUser!.ID = session.userID
                conm.currentUser!.login = user.login
                conm.currentUser!.password = user.password
                
                if QBChat.instance().isLoggedIn() {
                    QBChat.instance().logout()
                    if strongSelf.dialogs != nil {
                        strongSelf.dialogs = []
                        strongSelf.dialogsUsers = []
                        strongSelf.messagesIDsToDelete.removeAll(false)
                    }
                    strongSelf.privacyManager.reset()
                }
                
                QBChat.instance().loginWithUser(user)
                conm.chatLoginCompletion = completion
            }
            }) { (response: QBResponse!) -> Void in
                completion(success: false, errorMessage: response.error.error.localizedDescription)
                println(response.error.error.localizedDescription)
        }
    }
    
    /**
    *   Chat delegates
    */
    
    func chatDidFailWithError(code: Int) {
        if self.chatLoginCompletion != nil {
            self.chatLoginCompletion(false, "chat did fail with code" + String(code))
            self.chatLoginCompletion = nil
        }
    }
    
    func chatDidLogin() {
        self.presenceTimer = NSTimer.scheduledTimerWithTimeInterval(kChatPresenceTimeInterval, target: self, selector: Selector("sendChatPresence"), userInfo: nil, repeats: true)
        self.privacyManager.retrieveDefaultPrivacyList()
    }
    
    func chatDidReceivePrivacyList(privacyList: QBPrivacyList!) {
        if self.chatLoginCompletion != nil {
            self.chatLoginCompletion(true, nil)
            self.chatLoginCompletion = nil
        }
    }
    
    func chatDidNotReceivePrivacyListWithName(name: String!, error: AnyObject!) {
        if self.chatLoginCompletion != nil {
            self.chatLoginCompletion(true, nil)
            self.chatLoginCompletion = nil
        }
    }
    
    func sendChatPresence() {
        if QBChat.instance().isLoggedIn() {
            QBChat.instance().sendPresence()
            println( QBChat.instance().delegates() )
        }
    }
    
    /**
    Observers
    */
    func startObservingMessagesToDelete() {
        
        messagesBond.didInsertListener = { [unowned self] (array, indices) in
            var messIDs = NSArray(array: self.messagesIDsToDelete.value)
            var messIDsSet: Set<NSObject> = NSSet(array: messIDs as [AnyObject]) as Set<NSObject>
            
            QBRequest.deleteMessagesWithIDs(messIDsSet, successBlock: { [weak self] (response: QBResponse!) -> Void in
                println(response)
                if let strongSelf = self {
                    for (index, object) in enumerate(messIDs) {
                        strongSelf.messagesIDsToDelete.removeAtIndex(index)
                    }
                }
                }, errorBlock: { (response: QBResponse!) -> Void in
                    println(response.error)
            })
        }
        
        self.messagesIDsToDelete ->> messagesBond
    }
    
    deinit{
        QBChat.instance().removeDelegate(self)
    }
    
    
}