//
//  DataViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/18/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
//import ALCameraViewController
import Parse

class CaptureViewController: UIViewController, CACameraSessionDelegate
{
    
    //MARK: Private API
    var cameraView:CameraSessionView?
    var capturedImage:UIImage?
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var restartCamera: UIButton!
    @IBOutlet weak var postButton: UIButton!
    
    var user:PFUser{
        return PFUser.currentUser()!;
    }
    
    
    // MARK: - Lifecycle
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        
        stopCamera();
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        startCamera();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        startCamera()
        
        setupViews();
    }

    /// Sets up apperance on the Storybord Views
    func setupViews() -> Void
    {
        // Rounded Buttons
        postButton.layer.cornerRadius = CGRectGetWidth(postButton.frame) / 2;
        restartCamera.layer.cornerRadius = CGRectGetWidth(restartCamera.frame) / 2;
    }
    
    // MARK: - Camera
    func setupCamera() -> Void {
        cameraView = CameraSessionView(frame: view.frame);
        cameraView!.delegate = self
    }
    
    func startCamera() ->Void{
        if cameraView == nil{
            setupCamera();
        }
        hidePreview();
        
        if cameraView!.hidden == true{
            // The camera view was just hidden
            cameraView!.hidden = false;
            cameraView!.alpha = 1;          // Full opacity
        }
        
        view.addSubview(cameraView!);
    }
    
    func stopCamera() -> Void{
        cameraView?.removeFromSuperview();
        cameraView = nil;
    }
    
    func removeCamera() -> Void {
        assert(cameraView != nil, "cameraView is not setup at this point");
        if view.subviews.contains(cameraView!){
            cameraView!.removeFromSuperview();
        }
        cameraView = nil;
        
    }
    
    func didCaptureImage(image: UIImage!, withCamera cameraType: Int32) {
        previewImage(image);
        
        cameraView!.alpha = 1;          // Full opacity
        
        UIView.animateWithDuration(0.5, delay: 0, options: [.CurveEaseIn], animations: {
            self.cameraView!.alpha = 0;
        }) { (complete:Bool) in
            if complete{
                // Just Hide the CameraView
                self.cameraView!.hidden = true;
            }
        }
    }
    
    
    // MARK: UI
    func previewImage(image:UIImage) -> Void {
        restartCamera.hidden = false;
        postButton.hidden = false;
        
        imagePreview.hidden = false;
        imagePreview.image = image;

        capturedImage = image;
        
        postButton.setTitle("Post", forState: .Normal);
        postButton.enabled = true;
    }
    
    func hidePreview() -> Void {
        imagePreview.hidden = true;
        restartCamera.hidden = true
        postButton.hidden = true;
    }
    
    @IBAction func restartCameraAction(sender: AnyObject) {
        startCamera();
    }
    
    @IBAction func postAction(sender: UIButton) {
        assert(capturedImage != nil);
        
        // Disable Mulitple Posting
        postButton.setTitle("Posting..", forState: .Normal);
        postButton.enabled = false;
        postImageToParse(capturedImage!);
    }
    
    // MARK: - Database Operations
    func postImageToParse(image:UIImage) -> Void {
        let imageData:NSData = UIImageJPEGRepresentation(image, 1.0)!;
        
        let post = PFObject(className: "Post");
        post["picture"] = PFFile(name: "img.jpeg", data: imageData);
        if let lastLocation = Helper.getLastKnownUserLocation(){
            post["location"] = PFGeoPoint(latitude: lastLocation.latitude, longitude: lastLocation.longitude);
        }
        else{
            print("!! Error: Cannot determine location :(");
            return;
        }
        post["comment"] = "Test/Glimpse/1.0/iOSApp";
        post["user"] = user;
        
        post.saveInBackgroundWithBlock { (success:Bool, error:NSError?) in
            
            if success{
                print("* Post Uploaded Successfully!");
                // Alert then start camera again
                Helper.showQuickAlert("Posted!", message: "", viewController: self);
            }
            else{
                print("! Error Posting: ", error!.description);
                // Alert then start camera again
                Helper.showQuickAlert("Error!", message: error!.description, viewController: self);
            }
            
            self.startCamera();
        }
    }
}

