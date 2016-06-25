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
import AASquaresLoading
import EZSwipeController

class ProfileTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, MFMessageComposeViewControllerDelegate
{
    // MARK: - Public Properties
    /// Root view controller <EZSwipe Controller> that instantiated us
    var rootSwipeController:RootViewController?
    
    /// Segue Handler for Swipe to Dismiss
    var interactor:Interactor!
    
    // MARK: - Private Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerVisualEffectView: UIVisualEffectView!
    @IBOutlet var backgroundImageView: PFImageView!
    @IBOutlet weak var profileImageView: PFImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var logoutButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var imagePicker:UIImagePickerController!
    
    /// Collection View Data Controller 
    /// The Requests Our User Has Made
    private var requests:[PFObject]?{
        didSet{
            guard let nonNilRequests = requests else{
                collectionView.reloadData();
                return;
            }
            if (nonNilRequests.isEmpty){
                requests = nil;
            }
            
            collectionView.reloadData();
        }
    }
    
    /// The Request<PFObject> the user has selected
    private var selectedRequest:PFObject?{
        didSet{
            guard let _ = selectedRequest else{
                return
            }
            performSegueWithIdentifier(SegueFullScreen, sender: nil);
        }
    }
    
    /// Auto Loader for view controller
    /// Note: - turns on automatically when set off in following view controller appear cycle
    //  Note: ** Turn this on when delaing with loading alerts where return from Segues occur**
    var autoLoad:AutoLoad! = .On;
    
    /// Is there a user logged in at this point?
    private var userLoggedIn:Bool{
        return (PFUser.currentUser() == nil) ? false : true;
    }
    
    /// Current user who is logged in
    private var user:PFUser{
        return PFUser.currentUser()!;
    }
    
    // MARK: Constants
    private let loginSegue:String = "Segue_Login";
    private let collectionCellIdentifier:String = "requestCell";
    private let SegueFullScreen:String = "Segue_FullScreenImage";
    private let extendedCellSize:CGSize = CGSizeMake(210, 58);
    private let defaultCellSize:CGSize = CGSizeMake(160, 58);
    
    // MARK: - Lifecycle
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        // Status Bar
        UIApplication.sharedApplication().statusBarStyle = .Default;
        
        if userLoggedIn == false{
            // Logout button needs to be changed
            clearUserData();
            changeLogoutButton();
            
            return;
        }
        else if (self.autoLoad == AutoLoad.Off){
            autoLoad = .On;
            return;
        }
        
        // AT this point call user activity stuff they wont throw asserts
        
        // Do User Account Activity Stuff
        toggleLoading(.Start);
        fetchUserRequests { (finished) in
            self.toggleLoading(.Stop);
        };
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        if (userLoggedIn == false){
            // Logout button needs to be changed
            return;
        }
        
        // AT this point call user activity stuff they wont throw asserts
        self.interactor = Interactor();
        
        // Do User Account Activity Stuff
        fetchProfileImage();
        fetchUserName();
    }
    
    /// Adds Styles and Appearance to views on storyboard
    func setupViews() -> Void {
        // Status Bar
        UIApplication.sharedApplication().statusBarStyle = .Default;
        
        // View Setup
        profileImageView.layer.cornerRadius = Helper.getDefaultCornerRadius();
        profileImageView.layer.masksToBounds = true;
        
        headerVisualEffectView.layer.cornerRadius = Helper.getDefaultCornerRadius();
        headerVisualEffectView.layer.masksToBounds = true;
        
        backgroundImageView.layer.cornerRadius = Helper.getDefaultCornerRadius();
        backgroundImageView.layer.masksToBounds = true
        
        logoutButton.layer.cornerRadius = 5;
        
        logoutButton.layer.cornerRadius = Helper.getDefaultCornerRadius();
        logoutButton.layer.borderColor = Helper.getGlimpseOrangeColor().CGColor;
        logoutButton.layer.borderWidth = 2;
        
        headerView.sendSubviewToBack(backgroundImageView);
        
        collectionView.indicatorStyle = .Black;
        
        changeLogoutButton();
    }

    func clearUserData(){
        let defaultImage:UIImage = UIImage(named: "Empty User")!;
        backgroundImageView.image = defaultImage;
        profileImageView.image = defaultImage;
        nameLabel.text = "Name";
        
        self.requests = nil;
    }
    
    //MARK: - Action
    func changeLogoutButton(){
        if userLoggedIn{
            // User is logged in
            logoutButton.setTitle("Logout", forState: .Normal);
            
            logoutButton.removeTarget(nil, action: nil, forControlEvents: .AllEvents);
            logoutButton.addTarget(self, action: #selector(ProfileTableViewController.logoutAction(_:)), forControlEvents: .TouchUpInside);
        }
        else{
            // User is logged out
            logoutButton.setTitle("Login", forState: .Normal);
            
            logoutButton.removeTarget(nil, action: nil, forControlEvents: .AllEvents);
            logoutButton.addTarget(self, action: #selector(ProfileTableViewController.gotoLoginScreen), forControlEvents: .TouchUpInside);
        }
    }
    
    @IBAction func logoutAction(sender: UIButton) {
        // Avoid Double Tap
        sender.enabled = false;
        
        logout { (finished) in
            // Enable ReTap
            sender.enabled = true;
            self.clearUserData();
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
    
    func toggleLoading(operation:LoadingOption){
        struct Holder{
            static var loading:AASquaresLoading?
        }
        
        switch operation {
            case .Start:
                // Alloc Init
                
                if (Holder.loading == nil){
                    Holder.loading = AASquaresLoading(target: self.view, size: 40);
                }
                else {
                    Holder.loading?.stop();
                    Holder.loading = AASquaresLoading(target: self.view, size: 40);
                }
                
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

    
    // MARK: Tap Actions
    @IBAction func tappedImage(sender: UITapGestureRecognizer) {
        if userLoggedIn == false{
            gotoLoginScreen();
            return;
        }
        presentViewController(imagePicker, animated: true, completion: nil);
    }
    
    @IBAction func longPressedImage(sender: UILongPressGestureRecognizer) {
        if userLoggedIn == false{
            gotoLoginScreen();
            return;
        }
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
        controller.dismissViewControllerAnimated(true, completion: nil);
    }
    
    //MARK: - TextField
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag != 1{
            return;
        }
        else if textField.text == nil || textField.text == ""{
            return
        }
        else if (userLoggedIn == false){
            gotoLoginScreen();
            return
        }
        
        let newName = textField.text!;
        updateUserName(newName) { (finished) in
            
            if finished == false{
                Helper.showQuickAlert("Failed to Save :/", message: "", viewController: self);
                return
            }
            
            // Name Updated Successfully!
            self.nameLabel.text = newName;
            self.nameLabel.hidden = false;
            textField.removeFromSuperview();
        }
        
        textField.text = "Saving...";
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false;
    }
    
    //MARK: - Image Picker Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            // Toggle Loading
            // Turn OFF Auto Load otherwise our Loading Alert will be intercepted!
            autoLoad = .Off;
            toggleLoading(.Start);
            
            uploadProfileImage(pickedImage, completion: { (success) in
                // Toggle Loading
                self.toggleLoading(.Stop);
                
                if (!success){
                    // Clear the imageView on fail
                    self.profileImageView.image = nil;
                }
            })
            
            // Update UI
            profileImageView.image = pickedImage;
            backgroundImageView.image = pickedImage;
        }
        
    }
    
    //MARK: - TableView
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        print("Selected: ", indexPath.row);
    }
    
    //MARK: - Database Operations
    /// Updates Profile Image 
    /// Note: Database Operation
    ///       **Toggle Loading And Update Data on Handler**
    
    func uploadProfileImage(newImage:UIImage, completion:(success:Bool) -> Void) -> Void {
        assert(PFUser.currentUser() != nil, "User must be logged in to update profile pic!");
        
        let imageData:NSData = UIImageJPEGRepresentation(newImage, 1.0)!;
        let imageFile:PFFile = PFFile(name: "profile.jpeg", data: imageData)!;
        
        imageFile.saveInBackgroundWithBlock({ (success:Bool, error:NSError?) in
            if (error == nil && success)
            {
                self.user.setObject(imageFile, forKey: "picture");
                self.user.saveInBackgroundWithBlock({ (saved, error:NSError?) in
                    if (error == nil && saved)
                    {
                        completion(success: true);
                        
                        print("* Updated Profile Picture!");
                        Helper.showQuickAlert("Saved!", message: "", viewController: self);
                    }
                    else{
                        print("! Error Linking Photo to User Account");
                        completion(success: false);
                    }
                });
            }
            else{
                print("! Error Uploading Photo");
                completion(success: false);
            }
        });
    }
    
    func updateUserName(newName:String, completion:(finished:Bool) -> Void)
    {
        assert(PFUser.currentUser() != nil);
        
        user["name"] = newName;
        user.saveInBackgroundWithBlock { (saved:Bool, error:NSError?) in
            if saved && error == nil{
                completion(finished: true);
            }
            else{
                completion(finished: false);
            }
        }
    }
    
    /// Loads user profile image
    func fetchProfileImage() -> Void {
        assert(userLoggedIn);
        
        if let profilePic = user["picture"] as? PFFile{
            profileImageView.file = profilePic;
            backgroundImageView.file = profilePic;
            
            profileImageView.loadInBackground();
            backgroundImageView.loadInBackground();
            
            print("Profile Picture Loaded.");
        }
    }
    
    func fetchUserName() -> Void {
        assert(userLoggedIn);
        
        if let name = user["name"] as? String{
            nameLabel.text = name;
        }
    }
    
    /// Fetches User's Requests
    /// - Note: Activate Loading Alerts Outside
    func fetchUserRequests(completion:(finished:Bool) -> Void) -> Void
    {
        assert(userLoggedIn, "User must be logged in!");
        
        let query = PFQuery(className: "Request");
        query.whereKey("owner", equalTo: user)
        query.findObjectsInBackgroundWithBlock { (results:[PFObject]?, error:NSError?) in
            
            completion(finished: true);
            
            if (results != nil && error == nil)
            {
                self.requests = results!
            }
            else{
                self.requests = nil;
            }
        }
        
    }
    
    func logout(completion:(finished:Bool) -> Void) -> Void{
        // Logout User
        PFUser.logOutInBackgroundWithBlock { (error:NSError?) in
            completion(finished: true);
            
            if (error == nil){
                let installation = PFInstallation.currentInstallation();
                installation.removeObjectForKey("user");
                installation.saveInBackground();
                
                self.gotoLoginScreen();
            }
            else{
                print("! Error Logging out", error!.description);
                Helper.showAlert("Error", message: error!.description, viewController: self);
            }
        }
    }
    
    // MARK: - Navigation
    func gotoLoginScreen() -> Void {
        performSegueWithIdentifier(loginSegue, sender: nil);
    }
    
    //MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == SegueFullScreen)
        {
            assert(selectedRequest != nil, "Post must be selected to segue");
            
            let dvc = segue.destinationViewController as! FullScreenImageViewController
            
            // Animated Transition
            dvc.transitioningDelegate = self;
            dvc.interactor = interactor;
            dvc.request = selectedRequest!
        }
    }
}

extension ProfileTableViewController: UICollectionViewDelegate, UICollectionViewDataSource
{
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (requests == nil){
            return 1;
        }
        
        return requests!.count;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(collectionCellIdentifier, forIndexPath: indexPath) as! ProfileRequestCell;
        
        // Add Border to the cell
        cell.layer.cornerRadius = Helper.getDefaultCornerRadius();
        cell.layer.borderColor = Helper.getGlimpseOrangeColor().CGColor;
        cell.layer.borderWidth = 2;
        cell.layer.masksToBounds = true;
        
        guard let nonNilRequest = requests where userLoggedIn else{
            
            var cellText:String!
            if userLoggedIn == false{
                cellText = "You're not logged in.";
            }
            else{
                cellText = "Make a request. They will live here.";
            }
            cell.requestLabel.text = cellText
            
            return cell;
        }
        
        let index = indexPath.row;
        let request = nonNilRequest[index];
        
        cell.requestLabel.text = request["request"] as? String;
        
        return cell;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if (requests == nil || userLoggedIn == false)
        {
            let topSpace:CGFloat = (collectionView.frame.height - extendedCellSize.height) / 2;
            collectionView.contentInset = UIEdgeInsets(top: topSpace, left: 0, bottom: topSpace, right: 0);
            return extendedCellSize;
        }
        
        collectionView.contentInset = UIEdgeInsetsZero;
        return defaultCellSize;
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if (requests == nil){
            if userLoggedIn == false{
                self.gotoLoginScreen();
                
                return;
            }
            // We give the option to send the user to the Request Page
            if let destinationIndex = rootSwipeController?.getRequestPageIndex(){
                self.rootSwipeController?.switchToPage(destinationIndex);
            }
            return;
        }
        
        let index = indexPath.row;
        self.selectedRequest = requests![index];
        return;
    }
}


extension ProfileTableViewController: UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator();
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil;
    }
}

class ProfileRequestCell: UICollectionViewCell {
    @IBOutlet weak var requestLabel:UILabel!
}
