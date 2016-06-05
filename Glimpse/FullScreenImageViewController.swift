//
//  FullScreenImageViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/28/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class FullScreenImageViewController: UIViewController, UIGestureRecognizerDelegate
{
    
    // MARK: Public API
    var imageFile:PFFile!
    var imageComment:String?
    var post:PFObject!
    var interactor:Interactor? = nil
    
    // MARK: Private API
    var user:PFUser{
        return PFUser.currentUser()!;
    }
    
    // MARK: Private API
    @IBOutlet var imageView: PFImageView!
    @IBOutlet var commentLabel: UILabel!
    @IBOutlet weak var profileImageView: PFImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(post != nil, "Post must be set");
        
        // Post Stuff
        imageView.file = imageFile;
        imageView.loadInBackground();
        commentLabel.text = imageComment;
        
        viewPost();
        
        let user = post["user"] as! PFUser
        user.fetchIfNeededInBackgroundWithBlock{ (result:PFObject?, error:NSError?) in
            if error != nil{
                print("! Error Fetching User Image");
                return;
            }
            
            if let fetchedUser = result as? PFUser{
                let profilePic = fetchedUser["picture"] as? PFFile
                self.profileImageView.file = profilePic;
                self.profileImageView.loadInBackground();
            }
            else{
                print("! Error Fetching User Profile Photo");
            }
        }
        
        // Show Hints?
        //showHelperCircle();
        setupViews();
    }
    
    func setupViews(){
        
        imageView.layer.cornerRadius = 7;
        imageView.layer.masksToBounds = true;
        
        profileImageView.layer.cornerRadius = CGRectGetWidth(profileImageView.frame) / 2;
        profileImageView.layer.masksToBounds = true;
        
        /*
        // Add Gradient Layer to Comment Label
        let gradientLayer = CAGradientLayer();
        gradientLayer.frame = commentLabel.frame;
        
        // 3
        let customBlack:UIColor = view.backgroundColor!;
        let color1 = customBlack.CGColor as CGColorRef
        let color2 = UIColor.clearColor().CGColor as CGColorRef
        gradientLayer.colors = [color1, color2];
        
        // 4
        gradientLayer.locations = [0.0, 0.50];
        
        // 5
        commentLabel.layer.addSublayer(gradientLayer);
         */
    }

    //MARK: - Actions
    @IBAction func dismiss(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil);
    }
    
    func showHelperCircle(){
        let center = CGPoint(x: view.bounds.width * 0.5, y: 100)
        let small = CGSize(width: 30, height: 30)
        let circle = UIView(frame: CGRect(origin: center, size: small))
        circle.layer.cornerRadius = circle.frame.width/2
        circle.backgroundColor = UIColor.greenColor()
        circle.layer.shadowOpacity = 0.8
        circle.layer.shadowOffset = CGSizeZero
        view.insertSubview(circle, atIndex: 0);
        UIView.animateWithDuration(
            0.5,
            delay: 0.25,
            options: [],
            animations: {
                circle.frame.origin.y += 200
                circle.layer.opacity = 0
            },
            completion: { _ in
                circle.removeFromSuperview()
            }
        )
    }
    
    @IBAction func handleGesture(sender: UIPanGestureRecognizer) {
        let percentThreshold:CGFloat = 0.3
        
        // convert y-position to downward pull progress (percentage)
        let translation = sender.translationInView(view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        guard let interactor = interactor else { return }
        
        switch sender.state {
        case .Began:
            interactor.hasStarted = true
            dismissViewControllerAnimated(true, completion: nil)
        case .Changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.updateInteractiveTransition(progress)
        case .Cancelled:
            interactor.hasStarted = false
            interactor.cancelInteractiveTransition()
        case .Ended:
            interactor.hasStarted = false
            interactor.shouldFinish
                ? interactor.finishInteractiveTransition()
                : interactor.cancelInteractiveTransition()
        default:
            break
        }
    }
    
    //MARK: - Database Operations
    
    /// + Incrmentes views on this post
    /// + Registers self as viewer of this post
    func viewPost() -> Void
    {
        if let currentViewers = post["viewers"] as? [PFUser]{
            if currentViewers.contains(self.user){
                print("* Already viewed this post");
                return;
            }
        }
        
        // Do database operations
        post.incrementKey("views");
        post.addUniqueObject(self.user, forKey: "viewers");
        post.saveInBackgroundWithBlock { (success:Bool, error:NSError?) in
            if success{
                print("# Viewed post!");
            }
            else{
                print("! Failed to view post");
            }
        }
        
    }
}
