//
//  StoryViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/26/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import ParseUI
import Parse
import MapKit
import CoreLocation
import AASquaresLoading
import MGSwipeTableCell

enum Regions {
    case North, Campus, South;
}

enum AutoLoad {
    case On, Off;
}

class StoryViewController: UIViewController, MKMapViewDelegate
{
    // MARK: - Private API
    
    // MARK: Storyboard Outlet
    @IBOutlet weak var tableView: UITableView!
    
    //@IBOutlet var headerContentView: UIView!
    @IBOutlet var mapView: MKMapView!
    //@IBOutlet var headerSegment: UISegmentedControl!
    
    // Navigation Bar Stuff:
    @IBOutlet var navigationView: UIView!
    @IBOutlet var navigationTitleLabel: UILabel!
    @IBOutlet var navigationRefresh: UIActivityIndicatorView!
 
    /// Empty State Label
    @IBOutlet var emptyStateView: EmptyStateView!
    
    /// Segue Handler for Swipe to Dismiss
    var interactor:Interactor!
    
    /// Auto Loader for view controller
    /// Note: - turns on automatically when set off in following view controller appear cycle
    var autoLoad:AutoLoad!
    
    
    // Constants
    /// reuse identifer for the storyboard cell
    private let CellIdentifier:String = "simpleCellIdentifier";
    
    private let SegueFullScreen:String = "Segue_FullScreenImage";
    
    /// Selected Post 
    /// Note: - It is a reference to self.posts[PFObject]
    private var selectedRequest:PFObject?{
        didSet{
            if selectedRequest == nil{
                return;
            }
            performSegueWithIdentifier(SegueFullScreen, sender: nil);
        }
    }
    
    // These are all grouped together
    
    /// Locks the posts from auto updated the table view on its own
    /// - Note: if in a loop keep turning it on bc it auto turns on after 1 cycle
    private var tempLock:Bool = false;
    
    /// Universal Data Model for Displaying All Fetched Posts
    private var posts:[PFObject]?{
        didSet{
            print("Found ", posts?.count, " Posts.");
            if (posts == nil || posts!.isEmpty)
            {
                //posts = nil;
                
                // No Posts So Unhide the Empty State View
                emptyStateView.hidden = false;
                tableView.hidden = true;
                
                if (tempLock == false){
                    // Temp lock must be off to reload
                    tableView.reloadData();
                }
                // Auto turn off the lock
                tempLock = false;
                selectedRequest = nil;
            }
            else
            {
                if (tempLock == false){
                    // Temp lock must be off to reload
                    tableView.reloadData();
                }
                
                emptyStateView.hidden = true;
                tableView.hidden = false;
                
                // Auto turn off the lock
                tempLock = false;
                selectedRequest = nil;
                
                // Extract Indexes 
                var postIndexes:[Int] = [Int]();
                for request in posts!{
                    let requestIndex = request["index"] as! Int;
                    postIndexes.append(requestIndex);
                }
                
                self.setCurrentRequestIndex(postIndexes);
            }
        }
    }
    
    /// User Logged in?
    var userLoggedIn:Bool{
        return (PFUser.currentUser() == nil) ? false : true;
    }
    
    /// User who is logged in
    var user:PFUser{
        return PFUser.currentUser()!;
    }
    
    // MARK: - LifeCycle
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        // Status Bar
        UIApplication.sharedApplication().statusBarStyle = .LightContent;
        
        if autoLoad == .On{
            //refreshTableView();
        }
        
        autoLoad = .On;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        autoLoad = .On;
        self.interactor = Interactor();
        
        setupViews();
        refreshTableView();
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
        
        // Status Bar
        UIApplication.sharedApplication().statusBarStyle = .Default;
    }
    
    // MARK: - Setup Views
    func setupViews() -> Void {
        // Status Bar
        UIApplication.sharedApplication().statusBarStyle = .LightContent;
        
        self.edgesForExtendedLayout = .None;
        tableView.tableHeaderView = nil;
        tableView.contentInset = UIEdgeInsetsMake(-33, 0, -33, 0);
        
        //autoChangeBackgroundColors();
        //setBackgroundPattern(0);
        
        // Add Empty State View
        view.addSubview(emptyStateView);
        view.sendSubviewToBack(emptyStateView);
        // Center
        emptyStateView.center = view.center;
        let emptyBtn = emptyStateView.emptyStateButton;
        emptyBtn.titleLabel?.textAlignment = .Center;
        
        addGlimpseBorder(emptyBtn);
        emptyStateView.hidden = true;
        emptyBtn.addTarget(self, action: #selector(StoryViewController.emptyStateButtonAction(_:)), forControlEvents: .TouchUpInside);
    }
    
    func addGlimpseBorder(passedView:UIView)
    {
        passedView.layer.cornerRadius = Helper.getDefaultCornerRadius();
        //passedView.layer.borderWidth = 2;
        //passedView.layer.borderColor = Helper.getGlimpseOrangeColor().CGColor;
        passedView.layer.masksToBounds = true;
        
        //passedView.clipsToBounds = true;
    }
    
    func setBackgroundPattern(number:Int){
        assert(number <= 5);
        
        let patternImageFileName:String = "Pattern \(number)";
        let patternImage = UIImage(named: patternImageFileName)!;
        let patternColor = UIColor(patternImage: patternImage);
        view.backgroundColor = patternColor;
    }
    
    func autoChangeBackgroundColors(){
        // Update pattern every 5 seconds
        let timeInterval:NSTimeInterval = 5;
        let _ = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector: #selector(StoryViewController.updateBackgroundPattern), userInfo: nil, repeats: true);
    }
    
    func updateBackgroundPattern()
    {
        var patternColorArray = [UIColor]();
        
        // 1. Add all colors from assets
        for x in 1...5 {
            let patternImageFileName:String = "Pattern \(x)";
            let patternImage = UIImage(named: patternImageFileName)!;
            let patternColor = UIColor(patternImage: patternImage);
            patternColorArray.append(patternColor);
        }
        
        struct Holder{
            static var currentIndex:Int = 0 {
                didSet{
                    if currentIndex >= 5{
                        currentIndex = 0;
                    }
                }
            }
        }
        
        let index = Holder.currentIndex;
        let chosenPattern = patternColorArray[index];
        Holder.currentIndex += 1;
        
        self.view.backgroundColor = chosenPattern;
    }
    
    // MARK: - Database Operations
    /// Updates Post Feed
    /// - Notes:
    ///     - Compeletion Block Handler is trigger once data is refreshed!
    func fetchRequests(completion:(finished:Bool) -> Void) -> Void
    {
        print("> Fetching Random Posts..");
        
        // Count
        let countQuery = PFQuery(className:"Request")

        countQuery.countObjectsInBackgroundWithBlock {
            (count: Int32, error: NSError?) -> Void in
            if (error == nil) {
                print("Current Request Count: ", count);
                
                self.fetchRandomPosts(count, internalCompletion: completion, resultCompletion: nil, limit: 3);
            }
            else{
                print("Count Failed!");
                completion(finished: false);
            }
        }
        
    }
    
    /// __WARNING:__ Helper function DO NOT CALL; **CALL fetchRequests**
    private func fetchRandomPosts(maxCount:Int32, internalCompletion:((status:Bool) -> Void)?, resultCompletion:((status:Bool, foundPost:PFObject?) -> Void)?, limit:Int)
    {
        assert(maxCount > 0, "maxCount must be positive");
        // Generate 3 Random Numbers
        
        let totalCount: Int = limit;
        var randomNumArray: [Int] = []
        var i = 0
        while randomNumArray.count < totalCount {
            i += 1;
            let rand = Int(arc4random_uniform(UInt32(maxCount))) + 1;      // 1 - Count Range
            for(var ii = 0; ii < totalCount; ii += 1){
                if (randomNumArray.contains(rand) == false){
                    randomNumArray.append(rand)
                }
            }
        }
    
        assert(randomNumArray.count == limit);
        
        // Now Query these 3 Random Posts
        let query = PFQuery(className: "Request");
        
        query.limit = limit;
        query.includeKey("user");
        query.includeKey("followers");
        // Exlude our user's requests
        if (userLoggedIn){
            query.whereKey("owner", notEqualTo: self.user);
        }
        
        let currentRequestIndex:[Int] = user["currentRequests"] as! [Int];
        let skippedRequestIndex:[Int] = user["skippedRequests"] as! [Int];
        
        if currentRequestIndex.isEmpty{
            // If the user is new we do random posts:
            query.whereKey("index", containedIn: randomNumArray);
            
            // EXCEPT for the ones he has skipped before
            //query.whereKey("index", notContainedIn: skippedRequestIndex);
        }
        else{
            // We just give the user what he saw before
            query.whereKey("index", containedIn: currentRequestIndex);
            
            // EXCEPT for the ones he has skipped before
            //query.whereKey("index", notContainedIn: skippedRequestIndex);
        }
        
        query.findObjectsInBackgroundWithBlock {(newPosts:[PFObject]?, error:NSError?) in
            
            if (internalCompletion != nil){
                internalCompletion!(status: true);
            }
            else if (resultCompletion != nil){
                
                // We were called to ony get one request!
                if (error == nil && newPosts != nil && newPosts!.count == 1){
                    print("New post found ", newPosts![0].objectId);
                    resultCompletion!(status: true, foundPost: newPosts![0]);
                }
                else{
                    print("No new posts found!");
                    resultCompletion!(status: false, foundPost: nil);
                }
                return;
            }
            
            // We have been called to update the entire feed (first load call)
            if error == nil && newPosts != nil{
                self.posts = newPosts;
            }
            else{
                Helper.showQuickAlert("No Posts Found", message: "", viewController: self);
                self.posts = nil;
            }
        }
        
    }
    
    
    /// Fetches 1 new request **Safe Call**
    private func fetchNewRequest(completion:(success:Bool, newPost:PFObject?) -> Void) -> Void
    {
        print("> Fetching Random Request ");
        
        // Count
        let countQuery = PFQuery(className:"Request")
        
        countQuery.countObjectsInBackgroundWithBlock {
            (count: Int32, error: NSError?) -> Void in
            if (error == nil) {
                print("Current Request Count: ", count);
                
                self.fetchRandomPosts(count, internalCompletion: nil, resultCompletion: completion, limit: 1);
            }
            else{
                print("Count Failed!");
                completion(success: false, newPost: nil);
            }
        }
    }
    
    
    private func skipRequest(path:NSIndexPath)
    {
        assert(posts != nil);
        
        let index = path.row;
        
        // we dont want foced reload of table view
        tempLock = true;
        let skipPost: PFObject = self.posts![index];
        self.posts!.removeAtIndex(index);
        
        // Remove Cell Logic
        self.tableView.beginUpdates()
        self.tableView.deleteRowsAtIndexPaths([path], withRowAnimation: .Right);
        self.tableView.endUpdates();
        
        // Save it on our DB
        addSkipIndex(skipPost["index"] as! Int);
        
        addNewRequest(path);
    }
    
    private func addNewRequest(path:NSIndexPath){
        assert(posts != nil);
        
        toggleLoading(.Start);
        fetchNewRequest{ (success, newPost) in
            
            self.toggleLoading(.Stop);
            if (!success){
                // We dont want our table view to be behind our data controller
                self.tableView.reloadData();
                // No more new requests were found!
                return;
            }
            
            // The number of posts we skipped
            let insertIndex = path.row;
            
            // We want to add this new request with an animation and fade it in
            self.tempLock = true;
            self.posts!.insert(newPost!, atIndex: insertIndex);
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths([path], withRowAnimation: UITableViewRowAnimation.Fade);
            self.tableView.endUpdates();
            
            // We manually reload tv to update cell index
            self.tableView.reloadData();
        }
    }
    
    private func addSkipIndex(indexList:Int)
    {
        assert(userLoggedIn);
        
        // We add to the array of skipped user indexes
        user.addUniqueObject(indexList, forKey: "skippedRequests");
        
        // We remove this index from the current Request Index 
        //let currentRequestsIndex = user["currentRequests"] as! [Int];
        user.removeObject(indexList, forKey: "currentRequests");
        
        user.saveInBackground();
        
    }
    
    private func setCurrentRequestIndex(indexList:[Int]){
        assert(userLoggedIn);
        
        // This are the requests we are on
        user["currentRequests"] = indexList;
        user.saveInBackground();
    }
    
    private func refreshTableView() -> Void {
        self.navigationRefresh.startAnimating();
        self.toggleLoading(.Start);
        
        fetchRequests { (finished) in
            self.navigationRefresh.stopAnimating();
            self.toggleLoading(.Stop);
        }
    }
    
    @IBAction func refreshBarButtonItem(sender: UIBarButtonItem) {
        refreshTableView();
    }
    
    func toggleLoading(operation:LoadingOption){
        struct Holder{
            static var loading:AASquaresLoading?
        }
        
        switch operation {
        case .Start:
            
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
    
    func showActionSheet(targetCell: UITableViewCell, indexPath: NSIndexPath){
        let actionsheet = UIAlertController(title: "", message: "", preferredStyle: .ActionSheet);
        let skip:UIAlertAction = UIAlertAction(title: "Skip", style: .Default) { (action:UIAlertAction) in
            
            print("Skip post ", indexPath.row);
            
            self.skipRequest(indexPath);
        }
        let cancel:UIAlertAction = UIAlertAction(title: "Cancel", style: .Destructive) { (action:UIAlertAction) in
            actionsheet.dismissViewControllerAnimated(true, completion: nil);
        }
        
        actionsheet.view.tintColor = Helper.getGlimpseOrangeColor();
        actionsheet.addAction(skip);
        actionsheet.addAction(cancel);
        
        presentViewController(actionsheet, animated: true, completion: nil);
    }

    @IBAction func emptyStateButtonAction(sender: UIButton) {
        print("Empty State Action.");
        
        let newTitle = "Awesome!\nYou will be the first one to know.";
        sender.titleLabel?.lineBreakMode = .ByWordWrapping;
        sender.titleLabel?.textAlignment = .Center;
        sender.setTitle(newTitle, forState: .Normal);
        
        sender.enabled = false;
        
        return;
    }
    
    //MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueFullScreen{
            assert(selectedRequest != nil, "Post must be selected to segue");
            
            let dvc = segue.destinationViewController as! FullScreenImageViewController
            
            // Turn off auto refresh
            autoLoad = .Off;
            
            // Animated Transition
            dvc.transitioningDelegate = self;
            dvc.interactor = interactor;
            
            dvc.request = selectedRequest!
        }
    }
}

extension StoryViewController: UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator();
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil;
    }
}

extension StoryViewController: UITableViewDataSource, UITableViewDelegate, MGSwipeTableCellDelegate{
    
    // MARK: Configuration
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if posts == nil{
            return 0;
        }
        
        return posts!.count;
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGRectGetHeight(view.frame) / 3;
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min;
    }
    
    // MARK: Cell
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let bgColorView = UIView()
        bgColorView.backgroundColor = Helper.getGlimpseOrangeColor().colorWithAlphaComponent(0.7);
        cell.selectedBackgroundView = bgColorView
        
        return;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:RequestCell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as! RequestCell;
        
        let index:Int = indexPath.row;
        let post = posts![index];
        
        cell.requestLabel.text = post["request"] as? String;
        
        // Add Gesture Recognizer 
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(StoryViewController.cellHeldDown(_:)));
        cell.tag = index;
        cell.addGestureRecognizer(lpgr);
        
        cell.delegate = self // Receive callbacks via delegate
        
        //configure left buttons
        let leftButton = MGSwipeButton(title: "Skip", backgroundColor: Helper.getGlimpseOrangeColor());
        leftButton.tag = index;
        
        cell.leftButtons = [leftButton];
        
        cell.leftSwipeSettings.transition = MGSwipeTransition.Drag
        cell.leftExpansion.fillOnTrigger = true;
        cell.leftExpansion.threshold = 0.9;
        cell.leftExpansion.buttonIndex = 0;
        
        /*
        cell.rightExpansion.fillOnTrigger = true;
        cell.rightExpansion.threshold = 1.0;
        */
        
        return cell;
    }
    
    // MARK: Delegate
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
        
        assert(posts != nil, "Posts must exist in data struc at point of call");
        if userLoggedIn == false{
            print("No user logged in to see this request");
            return;
        }
        
        
        let index:Int = indexPath.row;
        selectedRequest = posts![index];
    }
    
    // MARK: Editing
    func swipeTableCell(cell: MGSwipeTableCell!, tappedButtonAtIndex index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        // NOTE: Index here refers to the button Index Positon NOT Rows!!
        let row:Int = cell.tag;
        print("Skip Request Index: ", row);
        self.skipRequest(NSIndexPath(forRow: row, inSection: 0));
        return true;
    }
    
    /*
    func swipeTableCell(cell: MGSwipeTableCell!, canSwipe direction: MGSwipeDirection) -> Bool {
        return true;
    }
    
    func swipeTableCell(cell: MGSwipeTableCell!, swipeButtonsForDirection direction: MGSwipeDirection, swipeSettings: MGSwipeSettings!, expansionSettings: MGSwipeExpansionSettings!) -> [AnyObject]! {
        
        swipeSettings.transition = .Border;
        swipeSettings.threshold = 1.5;
        
        if (direction == .LeftToRight)
        {
            let leftButtonArray:[MGSwipeButton] = [MGSwipeButton(title: "Skip", icon: nil, backgroundColor: Helper.getGlimpseOrangeColor())];
            return leftButtonArray;
        }
        
        return nil;
    }
    */
    
    func cellHeldDown(sender: UILongPressGestureRecognizer)
    {
        if (sender.state != .Began){
            return;
        }
        
        let row:Int = sender.view!.tag;
        print("Held Down Row: ", row);
        
        let selectedCell:UITableViewCell = sender.view as! UITableViewCell
        showActionSheet(selectedCell, indexPath: NSIndexPath(forRow: row, inSection: 0));
    }
}

extension StoryViewController: UIScrollViewDelegate{
    
}

class MapPin : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

class RequestCell: MGSwipeTableCell {
    @IBOutlet weak var requestLabel:UILabel!
}

class EmptyStateView: UIView {
    @IBOutlet var emptyStateLabel:UILabel!
    @IBOutlet var emptyStateButton:UIButton!
}

