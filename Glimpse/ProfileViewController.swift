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

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SimpleCamDelegate
{
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    var imagePicker:UIImagePickerController!
    
    var user:PFUser{
        return PFUser.currentUser()!;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(PFUser.currentUser() != nil);

        // View Setup
        profileImageView.layer.cornerRadius = CGRectGetWidth(profileImageView.frame) / 2;
        
        //let currentUser = PFUser.currentUser()!
        titleLabel.text = "Name";
        
        imagePicker = UIImagePickerController();
        imagePicker.delegate = self;
        imagePicker.sourceType = .PhotoLibrary;
        imagePicker.allowsEditing = false;
        
        
        let simpleCam = SimpleCam()
        simpleCam.delegate = self;
        //presentViewController(simpleCam, animated: true, completion: nil);
    }
    
    
    // MARK: Tests
    func simpleCam(simpleCam: SimpleCam!, didFinishWithImage image: UIImage!) {
        print("* picked Image");
    }
    
    func simpleCamDidLoadCameraIntoView(simpleCam: SimpleCam!) {
        
    }
    func simpleCamNotAuthorizedForCameraUse(simpleCam: SimpleCam!) {
        
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
        
        presentViewController(imagePicker, animated: true, completion: nil);
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            uploadProfileImage(pickedImage);
            // Update UI
            profileImageView.image = pickedImage;
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
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
