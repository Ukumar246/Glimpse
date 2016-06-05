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
import SimpleCam
import MessageUI

class ProfileTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, MFMessageComposeViewControllerDelegate
{
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerVisualEffectView: UIVisualEffectView!
    @IBOutlet var backgroundImageView: PFImageView!
    @IBOutlet weak var profileImageView: PFImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var logoutButton: UIButton!
    
    var imagePicker:UIImagePickerController!
    
    var user:PFUser{
        return PFUser.currentUser()!;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(PFUser.currentUser() != nil);

        //let currentUser = PFUser.currentUser()!
        fetchProfileImage();
        fetchUserName();
        
        imagePicker = UIImagePickerController();
        imagePicker.delegate = self;
        imagePicker.sourceType = .PhotoLibrary;
        imagePicker.allowsEditing = false;
        imagePicker.navigationBar.translucent = true;
        imagePicker.navigationBar.barTintColor = view.backgroundColor
        imagePicker.navigationBar.tintColor = Helper.getGlimpseOrangeColor()
        // Title color
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : Helper.getGlimpseOrangeColor()]
        
        setupViews();
    }
    
    /// Adds Styles and Appearance to views on storyboard
    func setupViews() -> Void {
        // View Setup
        profileImageView.layer.cornerRadius = 7;
        logoutButton.layer.cornerRadius = 5;
    }

    //MARK: - Action
    @IBAction func logoutAction(sender: UIButton) {
        
        // Avoid Double Tap
        sender.enabled = false;
        
        // Logout User
        PFUser.logOutInBackgroundWithBlock { (error:NSError?) in
            // Enable ReTap
            sender.enabled = true;
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

    @IBAction func share(sender: UIButton) {
        
        var website:String!

        switch sender.tag
        {
            // Instagram
            case 1:
                website = "https://www.instagram.com/theglimpseapp/";
                break;
            // Twitter
            case 2:
                website = "https://twitter.com/theglimpseapp";
                break;
            // Facebook
            case 3:
                website = "https://www.facebook.com/TheGlimpseApp/";
                break;
            // Open Link
            case 4:
                website = "http://www.getaglimpse.ca";
                break;
            default:
                break;
        }
        let url:NSURL = NSURL(string: website)!;
        let canOpen = UIApplication.sharedApplication().canOpenURL(url);
        print("Link: \(website) \t canOpen:\(canOpen)");
        
        UIApplication.sharedApplication().openURL(url);
    }
    
    @IBAction func tappedImage(sender: UITapGestureRecognizer) {
        presentViewController(imagePicker, animated: true, completion: nil);
    }
    
    @IBAction func longPressedImage(sender: UILongPressGestureRecognizer) {
        
    }
    
    @IBAction func tappedNameTf(sender: UITapGestureRecognizer) {
        
        let editNameTf = UITextField(frame: nameLabel.frame);
        editNameTf.tag = 1;
        editNameTf.borderStyle = .RoundedRect;
        editNameTf.tintColor = tableView.backgroundColor;
        editNameTf.keyboardAppearance = .Dark
        editNameTf.returnKeyType = .Done
        editNameTf.textAlignment = .Center
        editNameTf.autocapitalizationType = .Words
        editNameTf.textColor = Helper.getGlimpseOrangeColor();
        editNameTf.font = UIFont.boldSystemFontOfSize(16);
        nameLabel.hidden = true;
        
        editNameTf.backgroundColor = UIColor.whiteColor();
        headerVisualEffectView.addSubview(editNameTf);
        
        // TextField Targets
        editNameTf.delegate = self;
        
    }
    
    func share(){
        // Load Activity View Controller
        let messageComposeViewController = MFMessageComposeViewController()
        messageComposeViewController.messageComposeDelegate = self
        messageComposeViewController.recipients = ["4165712209"]
        messageComposeViewController.body = "Here's what I think about Glimpse: ";
        navigationController?.presentViewController(messageComposeViewController, animated: true) {
        }
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        
        print("* Message Sent!");
        controller.dismissViewControllerAnimated(true, completion: nil);
    }
    
    //MARK: TextField
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag != 1{
            return;
        }
        
        if textField.text == nil || textField.text == ""{
            return
        }
        
        let newName:String = textField.text!;
        user["name"] = newName;
        
        user.saveInBackgroundWithBlock { (saved:Bool, error:NSError?) in
            if saved && error == nil{
                self.nameLabel.text = newName;
                self.nameLabel.hidden = false;
                textField.removeFromSuperview();
            }
            else{
                Helper.showAlert("Error", message: "Check your internet", viewController: self);
            }
        }
        
        textField.text = "Saving...";
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false;
    }
    
    //MARK: Image Picker Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            uploadProfileImage(pickedImage);
            
            // Update UI
            profileImageView.image = pickedImage;
            backgroundImageView.image = pickedImage;
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - TableView
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
        
        let feedbackIndexPath = NSIndexPath(forRow: 0, inSection: 0);
        
        if indexPath == feedbackIndexPath{
            share();
        }
    }
    
    //MARK: - Database Operations
    
    /// Updates Profile Image 
    /// Note: Database Operation
    ///       **Updates UIImage View Profile Image View**
    func uploadProfileImage(newImage:UIImage) -> Void {
        let imageData:NSData = UIImageJPEGRepresentation(newImage, 1.0)!;
        let imageFile:PFFile = PFFile(name: "profile.jpeg", data: imageData)!;
        
        imageFile.saveInBackgroundWithBlock({ (success:Bool, error:NSError?) in
            if (error == nil && success)
            {
                self.user.setObject(imageFile, forKey: "picture");
                self.user.saveInBackgroundWithBlock({ (saved, error:NSError?) in
                    if (error == nil && saved)
                    {
                        print("* Updated Profile Picture!");
                        Helper.showQuickAlert("Saved!", message: "", viewController: self);
                    }
                    else{
                        print("! Error Linking Photo to User Account");
                        self.profileImageView.image = nil;
                    }
                });
            }
            else{
                print("! Error Uploading Photo");
                self.profileImageView.image = nil;
            }
        });
    }
    
    /// Loads user profile image
    func fetchProfileImage() -> Void {
        if let profilePic = user["picture"] as? PFFile{
            profileImageView.file = profilePic;
            backgroundImageView.file = profilePic;
            profileImageView.loadInBackground();
            backgroundImageView.loadInBackground();
        }
    }
    
    func fetchUserName() -> Void{
        if let name = user["name"] as? String{
            nameLabel.text = name;
        }
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
