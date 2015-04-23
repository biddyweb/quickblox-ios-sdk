//
//  SwipeableTableViewCellWithBlockButtons.swift
//  sample-chat-swift
//
//  Created by Anton Sokolchenko on 4/10/15.
//  Copyright (c) 2015 quickblox. All rights reserved.
//

class SwipeableTableViewCellWithBlockButtons : NSObject, SWTableViewCellDelegate
{
    
    var tableView: UITableView?
    /**
    *  SWTableViewCell delegate methods
    */
    
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        assert(cell.isKindOfClass(UserTableViewCell))
        
        var cell = cell as! UserTableViewCell
        
        if let strongTableView = tableView {
            cell.hideUtilityButtonsAnimated(true)
            let cellIndexPath = strongTableView.indexPathForCell(cell)
            // customize action sheet
            if let pressedButton = cell.rightUtilityButtons[index] as? UIButton {
                // block button
                if pressedButton.tag == 0 {
                    let actionSheetController = UIAlertDialog(style: UIAlertDialogStyle.ActionSheet, title: "Additional actions", andMessage: nil)
                    
                    /// P2P block
                    let selectedUser = cell.user!
                    let userIsBlockedInP2P = ConnectionManager.instance.privacyManager.isUserInBlockListP2P(selectedUser)
                    var messageP2P = userIsBlockedInP2P ? "Unblock user in 1-1 chat" : "Block user in 1-1 chat"
                    
                    actionSheetController.addButtonWithTitle(messageP2P, andHandler: { (index: Int) -> Void in
                        if userIsBlockedInP2P {
                            ConnectionManager.instance.privacyManager.unblockUserInP2PChat(selectedUser)
                        }
                        else {
                            UIAlertView(title: nil, message: "Note that you will not receive any private message from this user", delegate: nil, cancelButtonTitle: "Ok").show()
                            ConnectionManager.instance.privacyManager.blockUserInP2PChat(selectedUser)
                        }
                        // update block/unblock title
                        strongTableView.reloadRowsAtIndexPaths([cellIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                    })
                    
                    /// Groupchat block
                    let userIsBlockedInGroupChats = ConnectionManager.instance.privacyManager.isUserInBlockListGroupChats(selectedUser)
                    var messageGroupChat = userIsBlockedInGroupChats ? "Unblock user in all group chats" : "Block user in all group chats"
                    
                    actionSheetController.addButtonWithTitle(messageGroupChat, andHandler: { (index: Int) -> Void in
                        if userIsBlockedInGroupChats {
                            ConnectionManager.instance.privacyManager.unblockUserInGroupChats(selectedUser)
                        }
                        else {
                            UIAlertView(title: nil, message: "Note that you will not receive any group chat message from this user", delegate: nil, cancelButtonTitle: "Ok").show()
                            ConnectionManager.instance.privacyManager.blockUserInGroupChats(selectedUser)
                        }
                        // update block/unblock title
                        strongTableView.reloadRowsAtIndexPaths([cellIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                    })
                    
                    let appDelegate  = UIApplication.sharedApplication().delegate as! AppDelegate
                    actionSheetController.showInViewController(appDelegate.window!.rootViewController!)
                    
                }
                else if pressedButton.tag == 1 {
                    // delete button
                    
                    let alert = SwiftAlert(title: "Warning", message: "Do you really want to delete selected dialog?", cancelButtonTitle: "Cancel", otherButtonTitle: ["Delete"], didClick: { [weak self] (buttonIndex) -> Void in
                        if buttonIndex == 1 {
                            
                            SVProgressHUD.showWithStatus("Deleting...", maskType: SVProgressHUDMaskType.Clear)
                            assert(cell.dialogID != "")
                            QBRequest.deleteDialogWithID(cell.dialogID, successBlock: {(response: QBResponse!) -> Void in
                                SVProgressHUD.showSuccessWithStatus("Deleted")
                                ConnectionManager.instance.dialogs?.removeAtIndex(cellIndexPath!.row)
                                
                                strongTableView.deleteRowsAtIndexPaths([cellIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                                
                                }, errorBlock: { (response: QBResponse!) -> Void in
                                    SVProgressHUD.showErrorWithStatus("Error deleting")
                                    println(response.error.error)
                            })
                        }
                        })
                }
            }
        }
    }
}