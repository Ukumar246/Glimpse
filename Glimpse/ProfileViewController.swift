//
//  ProfileViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/26/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class ProfileViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(PFUser.currentUser() != nil);

        // View Setup
        profileImageView.layer.cornerRadius = CGRectGetWidth(profileImageView.frame) / 2;
        
        //let currentUser = PFUser.currentUser()!
        titleLabel.text = "Name";
    }
    

    //MARK: - Action
    @IBAction func rbbiAction(sender: UIBarButtonItem) {
        // Logout User 
        PFUser.logOutInBackgroundWithBlock { (error:NSError?) in
            if (error == nil)
            {
                print("* Logged out!");
                self.gotoLoginScreen();
            }
            else{
                print("! Error Logging out", error!.description);
            }
        }
    }
    
    @IBAction func tappedImage(sender: UITapGestureRecognizer) {
        
    }
    
    @IBAction func longPressedImage(sender: UILongPressGestureRecognizer) {
        print("* Long Pressed Image");
    }
    
    
    // MARK: - Navigation
    func gotoLoginScreen() -> Void {
        let loginVC_Identifier:String = "LoginViewController";
        let storyBoard = UIStoryboard(name: "Main", bundle: nil);
        
        let loginVC:UIViewController = storyBoard.instantiateViewControllerWithIdentifier(loginVC_Identifier);
        
        presentViewController(loginVC, animated: true, completion: nil);
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
