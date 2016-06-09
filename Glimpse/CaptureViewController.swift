//
//  DataViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/18/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import Parse

enum VCState {
    case VCLoaded, LoadingCamera, Camera, Preview, Posting;
}

struct State {
    /// Last system time this stuct was modifed
    var lastModified:NSDate!
    /// Current state of the view controller
    var currentState:VCState!{
        didSet{
            lastModified = NSDate();
        }
    };
    
    init(currentState: VCState) {
        self.currentState = currentState;
    }
    
    mutating func setState(newState: VCState){
        self.currentState = newState;
    }
}


class CaptureViewController: UIViewController, CACameraSessionDelegate, UITextFieldDelegate
{
    //MARK: Private API
    var cameraView:CameraSessionView?
    var capturedImage:UIImage?
    /// The state the view controller is currently in
    var state:State!
    
    // MARK: Storyboard Outlets
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var restartCamera: UIButton!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var commentVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var commentTextField: UITextField!
    
    var user:PFUser{
        return PFUser.currentUser()!;
    }
    
    // Constants:
    let characterLimit:Int = 140;
    
    // MARK: - Lifecycle
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        
        stopCamera();
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (state.currentState == .Preview || state.currentState == .Posting){
            print("# Locked State.");
        }
        else{
            startCamera();
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        state = State(currentState: .VCLoaded);
        
        setupCamera()
        startCamera()
        
        setupViews();
    }

    /// Sets up apperance on the Storybord Views
    func setupViews() -> Void
    {
        imagePreview.hidden = true;
        commentTextField.hidden = true;
        postButton.hidden = true;
        
        // Rounded Buttons
        postButton.layer.cornerRadius = CGRectGetWidth(postButton.frame) / 2;
        restartCamera.layer.cornerRadius = CGRectGetWidth(restartCamera.frame) / 2;
        
        commentVisualEffectView.layer.cornerRadius = 7;
        commentVisualEffectView.layer.masksToBounds = true;
        commentVisualEffectView.clipsToBounds = true;
        
        let attribute:[String: AnyObject] = [NSForegroundColorAttributeName: Helper.getGlimpseOrangeColor()];
        commentTextField.attributedPlaceholder = NSAttributedString(string: "Comment", attributes: attribute);
    }
    
    // MARK: - Camera
    func setupCamera() -> Void {
        cameraView = CameraSessionView(frame: view.frame);
        cameraView!.delegate = self
        // Call Camera Public API's Here
        
        state.setState(.LoadingCamera);
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
        state.setState(.Camera);
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

    func didCaptureImage(image: UIImage!, withFrontCamera frontCamera: Bool) {
        
        if frontCamera{
            // Flip Image
//            var flipedImage = UIImage(CGImage: image.CGImage!, scale: 1.0, orientation: .DownMirrored)
//            print("* Flipped Image");
        }
        
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
        commentTextField.hidden = false;
        
        commentTextField.text = nil;
        let attribute:[String: AnyObject] = [NSForegroundColorAttributeName: Helper.getGlimpseOrangeColor()];
        commentTextField.attributedPlaceholder = NSAttributedString(string: "Comment", attributes: attribute);
        
        commentVisualEffectView.hidden = false;
        
        imagePreview.hidden = false;
        imagePreview.image = image;

        capturedImage = image;
        
        postButton.setTitle("Post", forState: .Normal);
        postButton.enabled = true;
        commentTextField.enabled = true;
        
        state.setState(.Preview);
    }
    
    func hidePreview() -> Void {
        imagePreview.hidden = true;
        restartCamera.hidden = true
        postButton.hidden = true;
    }
    
    @IBAction func restartCameraAction(sender: AnyObject) {
        // Dismiss Keyboard
        commentTextField.resignFirstResponder();
        startCamera();
    }
    
    @IBAction func postAction(sender: UIButton) {
        assert(capturedImage != nil);
        
        // Disable Mulitple Posting
        postButton.setTitle("Posting...", forState: .Normal);
        postButton.enabled = false;
        commentTextField.enabled = false;
        
        if let commentString = commentTextField.text{
            postImageToParse(capturedImage!, comment: commentString);
        }
        else{
            postImageToParse(capturedImage!, comment: "");
        }
    }
    
    @IBAction func imageTapped(sender: UITapGestureRecognizer) {
        if commentTextField.isFirstResponder(){
            commentTextField.resignFirstResponder()
        }
    }
    
    // MARK: - Database Operations
    func postImageToParse(image:UIImage, comment:String) -> Void {
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
        post["comment"] = comment;
        post["user"] = user;
        post["views"] = 0;
        post["viewers"] = [];
        
        post.saveInBackgroundWithBlock { (success:Bool, error:NSError?) in
            
            if success{
                print("* Post Uploaded Successfully!");
                // Alert then start camera again
                Helper.showQuickAlert("Posted!", message: "Check your feed", viewController: self);
            }
            else{
                print("! Error Posting: ", error!.description);
                // Alert then start camera again
                Helper.showQuickAlert("Error!", message: error!.description, viewController: self);
            }
            
            self.startCamera();
        }
        
        state.setState(.Posting);
    }
    
    // MARK: - Actions
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= characterLimit
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.attributedPlaceholder = nil;
    }
}

