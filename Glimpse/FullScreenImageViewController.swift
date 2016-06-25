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
import AASquaresLoading

enum LoadingOption {
    case Start, Stop;
}

class FullScreenImageViewController: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate, UIScrollViewDelegate
{
    
    // MARK: Public API
    var request:PFObject!
    var interactor:Interactor? = nil
    
    // MARK: Private API
    
    /// Comments on this Request
    private var comments:[PFObject]?{
        didSet{
            guard let nonNilComments = comments else{
                commentsTableView.hidden = true;
                commentsTableView.reloadData();
                return
            }
            if (nonNilComments.count == 0){
                comments = nil;
                commentsTableView.hidden = true;
                commentsTableView.reloadData();
                return;
            }
            
            // We have comments
            commentsTableView.hidden = false;
            
            commentsTableView.reloadData();
        }
    }
    
    /// Current User
    private var user:PFUser{
        return PFUser.currentUser()!;
    }
    
    @IBOutlet weak var requestLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var commentBox: CommentBox!
    @IBOutlet weak var emptyStateLabel: UILabel!

    
    // MARK: Constants
    private let cellIdentifier:String = "commentCell";
    private let originalPoint:CGPoint = CGPointMake(0, 16);
    private let Segue_Camera:String = "Segue_CameraViewController";
    
    // MARK: - Lifecycle
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        showCameraButton(true);
        
        // Auto Fetch
        fetchComments();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(request != nil, "Post must be set");
        
        // Request Stuff
        requestLabel.text = request["request"] as? String;
        
        // Show Hints?
        //showHelperCircle();
        setupViews();
    }
    
    func setupViews(){
        
        // Table View Stuff
        commentsTableView.tableHeaderView = nil;
        let yOffset:CGFloat = 25;
        commentsTableView.contentInset = UIEdgeInsetsMake(yOffset, 0, 0, 0);
        let startOffset = CGPointMake(0, -25);
        commentsTableView.setContentOffset(startOffset, animated: false);
        
        let _:[String: AnyObject] = [NSForegroundColorAttributeName: Helper.getGlimpseOrangeColor()];
        
        // Appearance Stuff
        //addBorder(commentBox.cameraButton);
    
        // We dont want keyboard notifications
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FullScreenImageViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        
        // Label Stuff
        let postOwner:PFUser = request["owner"] as! PFUser;
        if (postOwner == user)
        {
            emptyStateLabel.text = "Well done! We'll let you know when your post has been commented on.";
        }
        else{
            emptyStateLabel.text = "Uh Oh! Take a Glimpse using the camera.";
        }
        
    }
    
    func addBorder(passedView:UIView)
    {
        passedView.layer.cornerRadius = Helper.getDefaultCornerRadius();
        passedView.layer.masksToBounds = true;
        passedView.layer.borderWidth = 2;
        passedView.layer.borderColor = Helper.getGlimpseOrangeColor().CGColor;
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
        
        guard let interactor = interactor else { return; }
        
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
        let extraHeight = keyboardHeight + 12;
        let movedUpPoint = CGPointMake(0, extraHeight);
        scrollView.setContentOffset(movedUpPoint, animated: true);
    }
    
    func moveCommentBoxDown(){
        //        scrollView.setContentOffset(originalPoint, animated: true);
    }
    
    func keyboardWillShow(notification:NSNotification) {
        let userInfo:NSDictionary = notification.userInfo!
        let keyboardFrame:NSValue = userInfo.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.CGRectValue()
        let keyboardHeight = keyboardRectangle.height
        moveCommentBoxUp(keyboardHeight);
    }
    
    /// Hides Camera Button At Bottom of Screen
    /// Note: - Dont repeat calls (inside scrollview methods)
    func hideCameraButton(animate: Bool){
        
        if (animate)
        {
            let animation:CATransition = CATransition();
            animation.type = kCATransitionFade;
            animation.duration = 0.4;
            commentBox.layer.addAnimation(animation, forKey: nil);
        }
        
        commentBox.hidden = true;
    }
    
    /// Shows Camera Button At Bottom of Screen
    func showCameraButton(animate: Bool){
        if (animate)
        {
            let animation:CATransition = CATransition();
            animation.type = kCATransitionFade;
            animation.duration = 0.4;
            commentBox.layer.addAnimation(animation, forKey: nil);
        }
        
        commentBox.hidden = false;
    }
    
    /// Camera Button Already Hidden?
    func cameraButtonIsHidden() -> Bool{
        return commentBox.hidden;
    }
    
    // MARK: - ScrollView
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        /*
         struct Holder{
            static var lastOffset:CGFloat!
        }
        
        let verticalOffset:CGFloat = scrollView.contentOffset.y;
        
        if (Holder.lastOffset > verticalOffset){
            // Scrolled UP
            
        }
        else{
            // Scrolled Down
            
        }
        
        Holder.lastOffset = verticalOffset;
        */
        if (cameraButtonIsHidden() == false){
            hideCameraButton(true);
        }
        
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        if (cameraButtonIsHidden() == true){
            showCameraButton(true);
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
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
    
    func dismissKeyboard()
    {
        return;
    }

    //MARK: - Actions
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
    
    func fetchComments()
    {
        print("Fetching Comments..");
        toggleLoading(.Start);
        
        let query = PFQuery(className: "Comment");
        query.whereKey("request", equalTo: self.request);
        
        query.findObjectsInBackgroundWithBlock { (results:[PFObject]?, error:NSError?) in
            self.toggleLoading(.Stop);
            
            if (results != nil && error == nil)
            {
                self.comments = results;
            }
            else{
                self.comments = nil;
            }
        }
    }
    
    //MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == Segue_Camera){
            let dvc = segue.destinationViewController as! CameraViewController
            dvc.request = self.request;
        }
    }
}

// MARK: - TableView
extension FullScreenImageViewController: UITableViewDataSource, UITableViewDelegate{

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.comments == nil) ? 0 : comments!.count;
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let commentCell = cell as! CommentCell;
        
        commentCell.imageComment.layer.cornerRadius = Helper.getDefaultCornerRadius();
        commentCell.imageComment.layer.masksToBounds = true;
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:CommentCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! CommentCell;
        
        let index = indexPath.row;
        let comment = self.comments![index];
        
        let photoFile = comment["photo"] as! PFFile
        cell.imageComment.file = photoFile;
        
        cell.emptyStateLabel.hidden = true;
        
        if (cell.loadingSquare == nil){
            cell.loadingSquare = AASquaresLoading(target: cell.contentView, size: 50);
        }
        else if (cell.imageComment.image != nil){
            cell.loadingSquare?.stop();
        }
        
        cell.loadingSquare?.backgroundColor = UIColor.clearColor();
        cell.loadingSquare?.setSquareSize(50);
        cell.loadingSquare?.color = Helper.getGlimpseOrangeColor();
        cell.loadingSquare?.start();
        cell.imageComment.loadInBackground { (loadedImage:UIImage?, error:NSError?) in
            cell.loadingSquare?.stop();
            cell.loadingSquare = nil;
            
            if (error != nil || loadedImage == nil){
                // Show the error on UI Label
                cell.emptyStateLabel.hidden = false;
            }
        }
        
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
        
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:{action, indexpath in
            
            print("Delete ", indexPath.row);
        });
        
        return [deleteRowAction];
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            
            print("Delete Action ", indexPath.row);
        }
    }
}

class CommentCell: UITableViewCell {
    //@IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageComment: PFImageView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    var loadingSquare:AASquaresLoading?
    
}

class CommentBox: UIView {
    @IBOutlet weak var cameraButton: UIButton!
}
