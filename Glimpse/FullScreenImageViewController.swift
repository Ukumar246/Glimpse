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
import MapKit

class FullScreenImageViewController: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate, UIScrollViewDelegate
{
    
    // MARK: Public API
    var request:PFObject!
    var interactor:Interactor? = nil
    
    // MARK: Private API
    var user:PFUser{
        return PFUser.currentUser()!;
    }

    @IBOutlet weak var profileImageView: PFImageView!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var requestLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var commentBox: CommentBox!

    // MARK: Constants
    let cellIdentifier:String = "commentCell";
    
    // MARK: - Lifecycle
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        
        let originalPoint = CGPointMake(0, 16);
        scrollView.contentOffset = originalPoint;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(request != nil, "Post must be set");
        
        // Request Stuff
        subjectLabel.text = request["subject"] as? String;
        requestLabel.text = request["request"] as? String;
        
        if let views = request["views"] as? Int
        {
            var viewsString:String!
            if (views <= 1){
                viewsString = "\(views) View";
            }
            else{
                viewsString = "\(views) Views";
            }
            
            //viewsLabel.text = viewsString;
        }
        else{
            //viewsLabel.text = "0 View";
        }
        
        let user = request["owner"] as! PFUser;
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
        
        profileImageView.layer.cornerRadius = 7;
        profileImageView.layer.masksToBounds = true;
     
        commentsTableView.tableHeaderView = nil;
        commentsTableView.contentInset = UIEdgeInsetsMake(-33, 0, -33, 0);
        
        let attributes:[String: AnyObject] = [NSForegroundColorAttributeName: Helper.getGlimpseOrangeColor()];
        
        commentBox.commentTextField.attributedPlaceholder = NSAttributedString(string: "Leave a comment", attributes: attributes);
        commentBox.layer.cornerRadius = 7;
        commentBox.layer.masksToBounds = true;
        
        let originalPoint = CGPointMake(0, 16);
        scrollView.contentOffset = originalPoint;
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FullScreenImageViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        
    }
    
    func autoChangeBackgroundColors(){
        var patternColorArray = [UIColor]();
        for x in 1...5 {
            let patternImageFileName:String = "Pattern \(x)";
            let patternImage = UIImage(named: patternImageFileName)!;
            let patternColor = UIColor(patternImage: patternImage);
            patternColorArray.append(patternColor);
        }
        
        
        var randIndex:Int = 0{
            didSet{
                if randIndex >= 5{
                    randIndex = 0;
                }
            }
        }
        
        for index in 1...5 {
            let seconds:Double = 5 * Double(index);
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                
                print("* Testing pattern ", randIndex);
                self.scrollView.backgroundColor = patternColorArray[randIndex];
                randIndex += 1;
            }
        }
    }
    
    //MARK: - GeoLocation
    func reverseGeoCodeLocation(longitude:CLLocationDegrees ,latitude:CLLocationDegrees)
    {
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            
            if (error != nil || placemarks == nil){
                print("Reverse geocoder failed with error" + error!.localizedDescription);
                return
            }
            
            let places:[CLPlacemark] = placemarks!;
            if (places.count > 0)
            {
                let pm:CLPlacemark = places[0];
                
                // Extract Formatted Address String
                let lines = pm.addressDictionary!["FormattedAddressLines"];
                
                print("\nLines: ", lines);
                let addressString = lines!.componentsJoinedByString("\n");
                print("\nAddress String: ", addressString);
                self.setGeoCodeLocationLabel(addressString);
            }
            else {
                print("Problem with the data received from geocoder");
            }
        })
    }
    
    func setGeoCodeLocationLabel(locality:String?){
        
    }
    
    //MARK: - Actions
    @IBAction func dismiss(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil);
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
    
    func moveCommentBoxUp(keyboardHeight: CGFloat){
        let extraHeight = keyboardHeight + 15;
        let movedUpPoint = CGPointMake(0, extraHeight);
        scrollView.setContentOffset(movedUpPoint, animated: true);
    }
    
    func moveCommentBoxDown(){
        let originalPoint = CGPointMake(0, 16);
        scrollView.setContentOffset(originalPoint, animated: true);
    }
    
    func keyboardWillShow(notification:NSNotification) {
        let userInfo:NSDictionary = notification.userInfo!
        let keyboardFrame:NSValue = userInfo.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.CGRectValue()
        let keyboardHeight = keyboardRectangle.height
        moveCommentBoxUp(keyboardHeight);
    }
    
    // MARK: - ScrollView
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
    }
    
    // MARK: - TextField
    func textFieldDidBeginEditing(textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        moveCommentBoxDown();
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
    
    func dismissKeyboard(){
        if commentBox.commentTextField.isFirstResponder(){
            commentBox.commentTextField.resignFirstResponder();
        }
    }
    
    //MARK: - Database Operations
    /// + Incrmentes views on this post
    /// + Registers self as viewer of this post
    func viewPost() -> Void
    {
        if let currentViewers = request["followers"] as? [PFUser]{
            if currentViewers.contains(self.user){
                print("* Already viewed this post");
                return;
            }
        }
        
        // Do database operations
        request.incrementKey("views");
        request.addUniqueObject(self.user, forKey: "viewers");
        request.saveInBackgroundWithBlock { (success:Bool, error:NSError?) in
            if success{
                print("# Viewed post!");
            }
            else{
                print("! Failed to view post");
            }
        }
    }
}

extension FullScreenImageViewController: UITableViewDataSource, UITableViewDelegate{
    
    // MARK: Configration
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5;
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let commentCell = cell as! CommentCell;
        
        commentCell.imageComment.layer.cornerRadius = 7;
        commentCell.imageComment.layer.masksToBounds = true;
        
        commentCell.profileImageView.layer.cornerRadius = 7;
        commentCell.profileImageView.layer.masksToBounds = true;
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:CommentCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! CommentCell;
        
        return cell;
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 374;     // Const for test
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min;
    }
    
    // MARK: Editing
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let moreRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "More", handler:{action, indexpath in
            
            print("MORE•ACTION");
        });
        moreRowAction.backgroundColor = UIColor(red: 0.298, green: 0.851, blue: 0.3922, alpha: 1.0);
        
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:{action, indexpath in
            
            print("DELETE•ACTION");
        });
        
        return [deleteRowAction, moreRowAction];
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }
}

class CommentCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var imageComment: UIImageView!
    
}

class CommentBox: UIView {
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var profileImageView: PFImageView!
}
