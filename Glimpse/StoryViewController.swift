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
import CSStickyHeaderFlowLayout
import MapKit
import CoreLocation

enum Regions {
    case North, Campus, South;
}

class StoryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate
{

    // MARK: Private API
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var headerContentView: UIView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var headerSegment: UISegmentedControl!
    
    @IBOutlet var navigationView: UIView!
    @IBOutlet var navigationTitleLabel: UILabel!
    @IBOutlet var navigationRefresh: UIActivityIndicatorView!
    
    var refresh:UIRefreshControl!
    /// local region where the user current is
    var localRegion:Regions!{
        didSet{
            collectionView.reloadData();
        }
    }
    
    // Constants
    ///tag for PFImageView inside of the UICollectionViewCell
    let ImageViewCELLTAG:Int = 1;
    /// tag for UILabel inside of the UICollectionViewCell
    let LabelViewCELLTAG:Int = 2;
    /// tag for UILabel inside of the header collection view
    let LabelViewHeaderCELLTAG:Int = 1;
    
    
    var posts:[PFObject]?{
        didSet{
            if posts != nil{
                print("\n\n>> Found \(posts!.count) posts: ");
                collectionView.reloadData();
                
                /* Print all posts found
                for post in posts!{
                    if let comment = post["comment"] as? String{
                        print(" - ", comment);
                    }
                }
                */
                
                annotatePostsOnMap(posts!);
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateLocalFeed();
        setupViews();
    }

    // MARK: - Setup Views
    func setupViews() -> Void {
        let layout:CSStickyHeaderFlowLayout = collectionView.collectionViewLayout as! CSStickyHeaderFlowLayout;
        
        // Locate the nib and register it to your collection view
        let headerNib = UINib(nibName: "StickyHeader", bundle: nil);
        collectionView.registerNib(headerNib, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: "stickyHeader");
        
        let width = CGRectGetWidth(self.view.frame);
        let height = CGRectGetHeight(self.headerContentView.frame);
        layout.parallaxHeaderReferenceSize = CGSizeMake(width, height);
        
        // map setup
        mapView.delegate = self;
        centerMap();
        
        addOverlayOnMap(.North);
        addOverlayOnMap(.Campus);
        addOverlayOnMap(.South);
        
        // Collection View
        refresh = UIRefreshControl();
        refresh.tintColor = UIColor.clearColor();
        refresh.addTarget(self, action: #selector(StoryViewController.refreshCollectionView(_:)), forControlEvents: .ValueChanged);
        collectionView.addSubview(refresh);
    }
    
    func updateLocalFeed() -> Void {
        localRegion = .Campus;
        fetchPosts(localRegion);
    }
    
    // MARK: - Database Operations
    /// Updates Post Feed
    func fetchPosts(region:Regions) -> Void {
        print("> Fetching \(localRegion) Posts..");
        
        let query = PFQuery(className: "Post");
        
        // Region Query
        let (NE, SW) = getRegionalBox(region);
        query.whereKey("location", withinGeoBoxFromSouthwest: SW, toNortheast: NE);
        
        query.orderByDescending("createdAt");
        query.findObjectsInBackgroundWithBlock { (newPosts:[PFObject]?, error:NSError?) in
            
            self.refresh.endRefreshing();
            self.navigationRefresh.stopAnimating();
            
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
        let (SWQ1_Lat, SWQ1_Lon) = (43.658247507179006, -79.48822975158691);
        
        let NEQ1 = PFGeoPoint(latitude: NEQ1_Lat, longitude: NEQ1_Lon);
        let SWQ1 = PFGeoPoint(latitude: SWQ1_Lat, longitude: SWQ1_Lon);
        
        if inputRegion == .North{
            return (NEQ1, SWQ1);
        }
        
        // Box 2
        let (NEQ2_Lat, NEQ2_Lon) = (43.67504211589516, -79.3778944015503);
        
        let SWQ2_Lat = 43.6471934083222;
        let SWQ2_Lon = -79.40394401550293;
        
        let NEQ2 = PFGeoPoint(latitude: NEQ2_Lat, longitude: NEQ2_Lon);
        let SWQ2 = PFGeoPoint(latitude: SWQ2_Lat, longitude: SWQ2_Lon);
     
        if inputRegion == .Campus{
            return (NEQ2, SWQ2);
        }
        
        let (NEQ3_Lat, NEQ3_Lon) = (43.65452163377025, -79.36948299407959);
        
        let SWQ3_Lat = 43.630111446719226;
        let SWQ3_Lon = -79.42467212677002;
        
        let NEQ3 = PFGeoPoint(latitude: NEQ3_Lat, longitude: NEQ3_Lon);
        let SWQ3 = PFGeoPoint(latitude: SWQ3_Lat, longitude: SWQ3_Lon);
        
        return (NEQ3, SWQ3);
    }
    
    // MARK: - Collection View
    // MARK: Datasource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if posts == nil{
            return 0;
        }
        
        return posts!.count;
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        // Appearance
        let imageView = cell.viewWithTag(ImageViewCELLTAG) as! PFImageView;
        imageView.layer.cornerRadius = 7;
        imageView.layer.masksToBounds = true;
        imageView.clipsToBounds = true;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell:UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCellIdentifer", forIndexPath: indexPath);
        let imageView:PFImageView = cell.viewWithTag(ImageViewCELLTAG) as! PFImageView;
        
        let post = posts![indexPath.row]
        imageView.file = post["picture"] as? PFFile;
        imageView.loadInBackground();
        
        let commentLabel:UILabel = cell.viewWithTag(LabelViewCELLTAG) as! UILabel;
        commentLabel.text = post["comment"] as? String;
        
        return cell;
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var view:UICollectionReusableView!
        
        if (kind == UICollectionElementKindSectionHeader){
            view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "header", forIndexPath: indexPath);
            let headerLabel = view.viewWithTag(LabelViewHeaderCELLTAG) as! UILabel
            headerLabel.text = "\(localRegion)";
        }
        else if (kind == CSStickyHeaderParallaxHeader){
            view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "stickyHeader", forIndexPath: indexPath)
            view.addSubview(self.headerContentView);
        }
        else{
            print("Collection View Error");
        }
        
        return view;
    }
    
    // MARK: Delegates
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if posts == nil || posts?.count == 0{
            return;
        }
        print("* Selected Image ", indexPath.row);
        
        // Fetch the post
        let post:PFObject = posts![indexPath.row];
        if let imageFile = post["picture"] as? PFFile{
            print("* File: ", imageFile);
        }
    }
    
    func refreshCollectionView(sender:UIRefreshControl) -> Void {
        
        navigationRefresh.startAnimating();
        fetchPosts(localRegion);
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
        print("* Removing all annotations..");
        
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations( annotationsToRemove );
    }
    
    func addOverlayOnMap(displayRegion:Regions) -> Void{
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
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if (overlay.isKindOfClass(MKPolygon.self))
        {
            let polygonOverlay = overlay as! MKPolygon;
            let aRenderer = MKPolygonRenderer(polygon: polygonOverlay);
            
            let polygonTitle = polygonOverlay.title;
            if polygonTitle == "\(Regions.North)"{
                aRenderer.fillColor = UIColor.cyanColor().colorWithAlphaComponent(0.2);
                aRenderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.7);
                aRenderer.lineWidth = 3;
            }
            else if polygonTitle == "\(Regions.Campus)"{
                aRenderer.fillColor = UIColor.yellowColor().colorWithAlphaComponent(0.3);
                aRenderer.strokeColor = UIColor.yellowColor().colorWithAlphaComponent(0.7);
                aRenderer.lineWidth = 3;
            }
            else{
                aRenderer.fillColor = UIColor.brownColor().colorWithAlphaComponent(0.2);
                aRenderer.strokeColor = UIColor.brownColor().colorWithAlphaComponent(0.7);
                aRenderer.lineWidth = 3;
            }
            
            
            return aRenderer;
        }
        else{
            let aRenderer = MKPolygonRenderer(polygon: overlay as! MKPolygon);
            
            aRenderer.fillColor = UIColor.whiteColor().colorWithAlphaComponent(0.2);
            aRenderer.strokeColor = UIColor.whiteColor().colorWithAlphaComponent(0.7);
            aRenderer.lineWidth = 3;
            
            return aRenderer;
        }
    }
    
    // MARK: - Actions
    @IBAction func headerSegmentChanged(sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex;
        
        if selectedIndex == 0{
            localRegion = .North;
        }
        else if selectedIndex == 1{
            localRegion = .Campus
        }
        else{
            localRegion = .South;
        }
        
        fetchPosts(localRegion);
    }
    
    @IBAction func mapAcessoryButtonTapped(sender: UIButton) {
        centerMap();
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
