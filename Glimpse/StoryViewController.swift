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

enum Regions {
    case North, Campus, South;
}

enum AutoLoad {
    case On, Off;
}

class StoryViewController: UIViewController, MKMapViewDelegate
{
    // MARK: - Private API
    var loadingSquares:AASquaresLoading?        // Loading Alert Shared Reference
    
    // MARK: Storyboard Outlet
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var collectionView: UICollectionView!
    //@IBOutlet var headerContentView: UIView!
    @IBOutlet var mapView: MKMapView!
    //@IBOutlet var headerSegment: UISegmentedControl!
    
    @IBOutlet var navigationView: UIView!
    @IBOutlet var navigationTitleLabel: UILabel!
    @IBOutlet var navigationRefresh: UIActivityIndicatorView!
 
    /// Segue Handler for Swipe to Dismiss
    var interactor:Interactor!
    
    /// Auto Loader for view controller
    /// Note: - turns on automatically when set off in following view controller appear cycle
    var autoLoad:AutoLoad!
    
    
    // Constants
    /// reuse identifer for the storyboard cell
    let CellIdentifier:String = "simpleCellIdentifier";
    
    let SegueFullScreen:String = "Segue_FullScreenImage";
    
    /// Selected Post 
    /// Note: - It is a reference to self.posts[PFObject]
    var selectedRequest:PFObject?{
        didSet{
            if selectedRequest == nil{
                return;
            }
            performSegueWithIdentifier(SegueFullScreen, sender: nil);
        }
    }
    
    /// Universal Data Model for Displaying All Fetched Posts
    var posts:[PFObject]?{
        didSet{
            if posts != nil{
                tableView.reloadData();
            }
            else{
                // There are no posts
            }
            selectedRequest = nil;
        }
    }
    
    // MARK: - LifeCycle
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        // Status Bar
        UIApplication.sharedApplication().statusBarStyle = .LightContent;
        
        if autoLoad == .On{
            refreshTableView();
        }
        
        autoLoad = .On;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        autoLoad = .On;
        self.interactor = Interactor();
        
        setupViews();
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
        setBackgroundPattern(3);
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
        
        let query = PFQuery(className: "Request");
        query.includeKey("user");
        query.includeKey("followers");
        
        query.orderByDescending("createdAt");
        query.limit = 3;
        
        query.findObjectsInBackgroundWithBlock {(newPosts:[PFObject]?, error:NSError?) in
            
            completion(finished: true);
            
            if error == nil && newPosts != nil{
                self.posts = newPosts;
            }
            else{
                Helper.showQuickAlert("No Posts Found", message: "", viewController: self);
                self.posts = nil;
            }
        }
    }
    
    func getRegionalBox(inputRegion:Regions) -> (PFGeoPoint,PFGeoPoint) {
        
        // Box 1
        let (NEQ1_Lat, NEQ1_Lon) = (43.77456454892858, -79.32231903076172);
        let (SWQ1_Lat, SWQ1_Lon) = (43.67622159755976, -79.4957184791565);
        
        let NEQ1 = PFGeoPoint(latitude: NEQ1_Lat, longitude: NEQ1_Lon);
        let SWQ1 = PFGeoPoint(latitude: SWQ1_Lat, longitude: SWQ1_Lon);
        
        if inputRegion == .North{
            return (NEQ1, SWQ1);
        }
        
        // Box 2
        let (NEQ2_Lat, NEQ2_Lon) = (43.67504211589516, -79.3778944015503);
        let (SWQ2_Lat, SWQ2_Lon) = (43.6471934083222, -79.40394401550293);
        
        let NEQ2 = PFGeoPoint(latitude: NEQ2_Lat, longitude: NEQ2_Lon);
        let SWQ2 = PFGeoPoint(latitude: SWQ2_Lat, longitude: SWQ2_Lon);
     
        if inputRegion == .Campus{
            return (NEQ2, SWQ2);
        }
        
        let (NEQ3_Lat, NEQ3_Lon) = (43.64706919340517, -79.37049150466919);
        let (SWQ3_Lat, SWQ3_Lon) = (43.630111446719226, -79.42467212677002)
        
        let NEQ3 = PFGeoPoint(latitude: NEQ3_Lat, longitude: NEQ3_Lon);
        let SWQ3 = PFGeoPoint(latitude: SWQ3_Lat, longitude: SWQ3_Lon);
        
        return (NEQ3, SWQ3);
    }
    
    func refreshTableView() -> Void {
        self.navigationRefresh.startAnimating();
        self.showLoadingSquare();
        
        fetchRequests { (finished) in
            self.navigationRefresh.stopAnimating();
            self.removeLoadingSquare();
        }
    }
    
    // MARK: - Map
    func centerMap() -> Void {
        // MAP
        let torontoLat = 43.66575385777062;
        let torntoLon = -79.39910531044006;
        let torontoCordinate:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: torontoLat, longitude: torntoLon);
        let torontoRegion = mapView.regionThatFits(MKCoordinateRegionMakeWithDistance(torontoCordinate, 2500, 2500));
        
        mapView.setRegion(torontoRegion, animated: true);
    }
    
    func centerMapOnRegion(region:Regions) -> Void {
        // MAP
        
        /*          Centers
         35 Cortland Ave, Toronto, ON M4R 1T7, Canada
         Latitude: 43.724467 | Longitude: -79.402657
         Centre of Q1
         
         
         129 College St, Toronto, ON M5T 1P5, Canada
         Latitude: 43.6598 | Longitude: -79.39064
         Centre of Q2
         
         
         433-441 Lake Shore Blvd W, Toronto, ON M5V, Canada
         Latitude: 43.638001 | Longitude: -79.394932
         Centre of Q3
        */
        
        var regionCenter:CLLocationCoordinate2D!
        var latDistance:CLLocationDistance!
        var lonDistnace:CLLocationDistance!
        
        if region == .North{
            regionCenter = CLLocationCoordinate2D(latitude: 43.724467, longitude: -79.402657);
            latDistance = 14000;
            lonDistnace = 16500;
        }
        else if region == .Campus{
            regionCenter = CLLocationCoordinate2D(latitude: 43.6598, longitude: -79.39064);
            latDistance = 3500;
            lonDistnace = 2200;
        }
        else{
            regionCenter = CLLocationCoordinate2D(latitude: 43.638001, longitude: -79.394932);
            latDistance = 2000;
            lonDistnace = 5500;
        }
        
        let torontoRegion = mapView.regionThatFits(MKCoordinateRegionMakeWithDistance(regionCenter, latDistance, lonDistnace));
        
        
        mapView.setRegion(torontoRegion, animated: true);
    }
    
    func annotatePostsOnMap(postArray:[PFObject]) -> Void {
        var annotations:Array = [MKAnnotation]();
    
        removeAllMapAnnotations();
        
        print("* Annotating posts..");
        for post in postArray{
            if let location = post["location"] as? PFGeoPoint{
                var postComment = post["comment"] as? String;
                if postComment == nil{
                    postComment = "No Comment";
                }
                
                let cordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude);
                let annotation = MapPin(coordinate: cordinate, title: postComment!, subtitle: "");
                
                annotations.append(annotation);
            }
        }
        
        mapView.addAnnotations(annotations);
    }
    
    func removeAllMapAnnotations() -> Void {
        
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations( annotationsToRemove );
    }
    
    func addOverlayOnMap(displayRegion:Regions) -> Void{
        
        // Remove All OverLay
        let currentOverlays = mapView.overlays;
        mapView.removeOverlays(currentOverlays);
        
        // Remove Annotations
        removeAllMapAnnotations();
        
        let (NE, SW) = getRegionalBox(displayRegion);      // Default Parse Query Format
        let NW = CLLocationCoordinate2DMake(NE.latitude, SW.longitude);             // Top Left     -NW
        let SE = CLLocationCoordinate2DMake(SW.latitude, NE.longitude);             // Bottom Right -SE
        
        var points:[CLLocationCoordinate2D] = [];
        
        points.append(CLLocationCoordinate2DMake(NE.latitude, NE.longitude));       // NE
        points.append(SE);       // SE
        points.append(CLLocationCoordinate2DMake(SW.latitude, SW.longitude));       // SW
        points.append(NW);       // NW
        
        let polygon = MKPolygon(coordinates: &points, count: 4);
        polygon.title = "\(displayRegion)";
        
        mapView.addOverlay(polygon);
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer
    {
        if (overlay.isKindOfClass(MKPolygon.self))
        {
            let polygonOverlay = overlay as! MKPolygon;
            let aRenderer = MKPolygonRenderer(polygon: polygonOverlay);
            
            let backgroundColor:UIColor = view.backgroundColor!
            aRenderer.fillColor = backgroundColor.colorWithAlphaComponent(0.2);
            aRenderer.strokeColor = backgroundColor.colorWithAlphaComponent(0.7);
            aRenderer.lineWidth = 3;
            
            return aRenderer;
        }
        else{
            let aRenderer = MKPolygonRenderer(polygon: overlay as! MKPolygon);
            return aRenderer;
        }
    }
    
    // MARK: - Actions
    @IBAction func mapAcessoryButtonTapped(sender: UIButton) {
        centerMap();
    }
    
    @IBAction func refreshBarButtonItem(sender: UIBarButtonItem) {
        refreshTableView();
    }
    
    func showLoadingSquare(){
        loadingSquares = AASquaresLoading(target: self.view, size: 40)
        loadingSquares!.backgroundColor = UIColor.clearColor();
        loadingSquares!.color = Helper.getGlimpseOrangeColor();
        loadingSquares!.setSquareSize(120);
        loadingSquares!.start()
    }
    
    func removeLoadingSquare(){
        loadingSquares?.stop();
    }
    
    func hideCollectionView() -> Void {
        // Animate Collection View Fade out
        // Pre animation
        /*
        collectionView.alpha = 1;
        collectionView.hidden = false;
        
        // Animation
        UIView.animateWithDuration(1.0, animations: {
            self.collectionView.alpha = 0.2;
            
            }, completion: { (finished:Bool) in
                self.collectionView.hidden = true;
        });
        */
    }

    func showCollectionView() -> Void {
        // Animate Collection View Fade out
        // Pre animation
        /*
        collectionView.alpha = 0;
        collectionView.hidden = false;
        
        // Animation
        UIView.animateWithDuration(1.0) {
                self.collectionView.alpha = 1;
        }
        */
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

extension StoryViewController: UITableViewDataSource, UITableViewDelegate{
    
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
        
        return cell;
    }
    
    // MARK: Delegate
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
        
        assert(posts != nil, "Posts must exist in data struc at point of call");
        
        let index:Int = indexPath.row;
        selectedRequest = posts![index];
    }
    
    // MARK: Editing
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:{action, indexpath in
            
            
        });
        
        return [deleteRowAction];
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle != .Delete){
            return
        }
        
        let index = indexPath.row;
        
        print("Deleted Row ", index)
        
        self.posts!.removeAtIndex(index);
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left);
    }
}

extension StoryViewController: UIScrollViewDelegate{
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset:CGFloat = scrollView.contentOffset.y;
        
        print("Offset: \(offset)");
    }
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

class RequestCell: UITableViewCell {
    @IBOutlet weak var requestLabel:UILabel!
}

