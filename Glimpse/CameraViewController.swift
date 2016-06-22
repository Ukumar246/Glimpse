//
//  CameraViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 6/16/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import AASquaresLoading

enum ViewControllerStates {
    case Camera, Preview, Posting;
}

class CameraViewController: UIViewController, CACameraSessionDelegate {

    // MARK: Public API
    var request:PFObject!
    
    // MARK: Storyboard Outlets
    @IBOutlet weak var cameraViewFrame: UIView!
    private var cameraView: CameraSessionView!
    
    @IBOutlet weak var imagePreview: UIImageView!
    
    @IBOutlet weak var leftBBi: UIButton!
    @IBOutlet weak var rightBBi: UIButton!
    
    @IBOutlet weak var testButton: UIButton!{
        didSet{
            if (Helper.testingOn() == false){
                testButton.removeFromSuperview();
            }
        }
    }
    
    @IBOutlet weak var navigationBarTitle: UILabel!

    // MARK: Private API
    private var capturedImage:UIImage?
    
    private var user:PFUser{
        return PFUser.currentUser()!
    }
    
    /// The state our screen is in.
    private var state:ViewControllerStates!{
        didSet
        {
            var newTitle:String = "";
            
            if (state == .Preview){
                rightBBi.hidden = false;
                newTitle = "Looks Great.";
                
                // The Left BBi now functions as restart camera
                // Remove all previous actions
                leftBBi.removeTarget(nil, action: nil, forControlEvents: .AllEvents);
                leftBBi.addTarget(self, action: #selector(CameraViewController.restartCamera(_:)), forControlEvents: .TouchUpInside);
                // Use Back Image
                let backImage:UIImage = UIImage(named: "Back")!;
                leftBBi.setImage(backImage, forState: .Normal);
            }
            else if (state == .Camera){
                rightBBi.hidden = true;
                newTitle = "Point. Answer";
                
                // The Left BBi now functions as exit screen
                leftBBi.removeTarget(nil, action: nil, forControlEvents: .AllEvents);
                leftBBi.addTarget(self, action: #selector(CameraViewController.dismissViewController), forControlEvents: .TouchUpInside);
                
                // Use Exit Image 
                let exitImage:UIImage = UIImage(named: "Exit")!;
                leftBBi.setImage(exitImage, forState: .Normal);
            }
            else if (state == .Posting){
                rightBBi.hidden = true;
                newTitle = "Posting...";
                
            }
            
            navigationBarTitle.text = newTitle;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(request != nil, "Request must be set");

        setupCamera();
        startCamera();
        
        setupViews();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        stopCamera();
    }
    
    func setupViews()
    {
        imagePreview.layer.cornerRadius = Helper.getDefaultCornerRadius()
        imagePreview.layer.masksToBounds = true;
        imagePreview.clipsToBounds = true;
        
        // Exit Action on Right BBi
        leftBBi.removeTarget(nil, action: nil, forControlEvents: .AllEvents);
        leftBBi.addTarget(self, action: #selector(CameraViewController.dismissViewController), forControlEvents: .TouchUpInside);
        // Exit Image
        let exitImage = UIImage(named: "Exit")!;
        leftBBi.setImage(exitImage, forState: .Normal);
    }
    
    
    // MARK: - Camera
    func setupCamera() -> Void {
        struct Holder{
            static var originalFrame:CGRect!
        }
        
        if (view.subviews.contains(cameraViewFrame)){
            // First time we are called
            Holder.originalFrame = cameraViewFrame.frame;
            cameraViewFrame.removeFromSuperview();
        }
        
        cameraView = CameraSessionView(frame: Holder.originalFrame);
        cameraView!.delegate = self;
        
        cameraView.layer.cornerRadius = Helper.getDefaultCornerRadius();
        cameraView.layer.masksToBounds = true;
        cameraView.clipsToBounds = true
        
        // Call Camera Public API's Here
    }
    
    func startCamera() ->Void{
        if cameraView == nil{
            setupCamera();
        }
        
        if cameraView!.hidden == true{
            // The camera view was just hidden
            cameraView!.hidden = false;
            cameraView!.alpha = 1;          // Full opacity
        }
        
        // Hide Preview 
        let animation:CATransition = CATransition();
        animation.type = kCATransitionFade;
        animation.duration = 0.7;
        cameraView.layer.addAnimation(animation, forKey: nil);
        
        
        imagePreview.hidden = true;
        
        
        view.addSubview(cameraView!);
        state = .Camera;
    }
    
    func stopCamera() -> Void{
        let animation:CATransition = CATransition();
        animation.type = kCATransitionFade;
        animation.duration = 0.7;
        cameraView.layer.addAnimation(animation, forKey: nil);
        cameraView?.removeFromSuperview();
    }
    
    // MARK: Delegate
    func didCaptureImage(image: UIImage!, withFrontCamera frontCamera: Bool) {
        
        if (frontCamera){
            // Flip Image
            let flippedImage = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: UIImageOrientation.LeftMirrored);
            
            previewImage(flippedImage);
            return;
        }
        
        previewImage(image);
    }
    
    // MARK: Processing 
    func previewImage(capturedImage:UIImage)
    {
        // we are in preview state
        state = .Preview;
        
        imagePreview.hidden = false;
        
        
        imagePreview.image = capturedImage;
        self.capturedImage = capturedImage;
        
        stopCamera();
    }
    
    // MARK: - Actions
    @IBAction func restartCamera(sender: UIButton) {
        startCamera();
    }
    
    @IBAction func postComment(sender:UIButton){
        print("Posting Image...");
        
        assert(capturedImage != nil);
        database_postComment(capturedImage!);
    }
    
    func toggleLoading(operation:LoadingOption){
        struct Holder{
            static var loading:AASquaresLoading?
        }
        
        switch operation {
        case .Start:
            
            // Alloc Init
            Holder.loading = AASquaresLoading(target: self.view, size: 40);
            
            // Start Loading
            Holder.loading!.backgroundColor = UIColor.clearColor();
            Holder.loading!.color = Helper.getGlimpseOrangeColor();
            Holder.loading!.setSquareSize(120);
            Holder.loading!.start();
            
            break;
        case .Stop:
            
            Holder.loading?.stop();
            
            break;
        }
        return;
    }
    
    // Test
    @IBAction func testUpload(sender: AnyObject) {
        let testImage = UIImage(named: "Toronto")!;
        database_postComment(testImage);
    }
    
    // MARK: - Database Operations
    func database_postComment(image: UIImage)
    {
        state = .Posting;
        toggleLoading(.Start);
        
        // Post to Parse
        let comment = PFObject(className: "Comment");
        
        let imageData:NSData = UIImageJPEGRepresentation(image, 1.0)!;
        comment["photo"] = PFFile(name: "pic.jpeg", data: imageData);
        comment["request"] = request;
        
        // Modify the request 
        request.addUniqueObject(user, forKey: "followers");
        
        PFObject.saveAllInBackground([request, comment]) { (success:Bool, error:NSError?) in
            
            self.toggleLoading(.Stop);
            
            if (success && error == nil){
                print("Comment Posted!");
                self.dismissViewController();
            }
            else{
                print("Error : ", error!.description);
                Helper.showAlert("Error", message: error!.description, viewController: self);
            }
        }
    }
    
    // MARK: - Navigation
    @IBAction func dismissViewController() {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}
