//
//  RootViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/18/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import ALCameraViewController
import CoreLocation
import EZSwipeController

class RootViewController: EZSwipeController, CLLocationManagerDelegate, EZSwipeControllerDataSource {

    //var pageViewController: UIPageViewController?

    //MARK: Private API
    // Location
    var locationManager:CLLocationManager!
    var monitorLocation:CLLocationCoordinate2D?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocationManager();
        
        // Monitor Location Setup
        monitorLocation = nil;
        
        view.backgroundColor = UIColor.blackColor()
        
        /*
            //CAMERA VC
            let cameraVC = ALCameraViewController(croppingEnabled: true) { (image:UIImage?) in
                print("Image Captured");
            }
         
        */
        
        
        /*
        // Configure the page view controller and add it as a child view controller.
        self.pageViewController = UIPageViewController(transitionStyle: .PageCurl, navigationOrientation: .Horizontal, options: nil)
        self.pageViewController!.delegate = self

        let startingViewController: CameraViewController = self.modelController.viewControllerAtIndex(0, storyboard: self.storyboard!)!
        let viewControllers = [startingViewController]
        self.pageViewController!.setViewControllers(viewControllers, direction: .Forward, animated: false, completion: {done in })

        self.pageViewController!.dataSource = self.modelController

        self.addChildViewController(self.pageViewController!)
        self.view.addSubview(self.pageViewController!.view)

        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        var pageViewRect = self.view.bounds
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            pageViewRect = CGRectInset(pageViewRect, 40.0, 40.0)
        }
        self.pageViewController!.view.frame = pageViewRect

        self.pageViewController!.didMoveToParentViewController(self)
        */
    }
    
    
    // MARK: - EZ Swipe View Controller
    override func setupView() {
        super.setupView()
        navigationBarShouldNotExist = true
        datasource = self
    }
    
    func viewControllerData() -> [UIViewController] {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil);
        
        let captureVC:UIViewController = storyBoard.instantiateViewControllerWithIdentifier("CaptureViewController");
        let storyVC:UIViewController = storyBoard.instantiateViewControllerWithIdentifier("StoryViewController");
        
        return [storyVC, captureVC];
    }
    
    /*
    func titlesForPages() -> [String] {
        return ["Karsh", "Best"];
    }
    */
    func indexOfStartingPage() -> Int {
        return 1;
    }
    /*
    func navigationBarDataForPageIndex(index: Int) -> UINavigationBar {
        var title = ""
        if index == 0 {
            title = "Story"
        } else if index == 1 {
            title = "Capture"
        }
        
        let navigationBar = UINavigationBar();
        navigationBar.barStyle = .Default;
        //navigationBar.barTintColor = UIColor.blackColor();
        
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.blackColor()]
        
        let navigationItem = UINavigationItem(title: title)
        navigationItem.hidesBackButton = true
        
        
        if index == 0 {
            let rightButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: self, action: nil)
            rightButtonItem.tintColor = UIColor.blackColor()
            
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = rightButtonItem
        } else if index == 1 {
            let rightButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Bookmarks, target: self, action: nil)
            rightButtonItem.tintColor = UIColor.blackColor()
            
            let leftButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Camera, target: self, action: nil)
            leftButtonItem.tintColor = UIColor.blackColor()
            
            navigationItem.leftBarButtonItem = leftButtonItem
            navigationItem.rightBarButtonItem = rightButtonItem
        }
        
        navigationBar.pushNavigationItem(navigationItem, animated: false)
        return navigationBar
    }
     */
    
    // MARK: - Location Manager
    func setupLocationManager(){
        locationManager  = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled()
        {
            locationManager.delegate = self;
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;  // 10 m accuracy
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("Location = \(locValue.latitude) \(locValue.longitude)");
        
        // run only once
        if monitorLocation == nil{
            monitorLocation = locValue
            startMonitoringGeotification(locValue, radius: 100, identifier: "THOT");
        }
    }
    
    func startMonitoringGeotification(cordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        // A
        let region = CLCircularRegion(center: cordinate, radius: radius, identifier: identifier);
        // B
        region.notifyOnEntry = true;
        region.notifyOnExit =  true;
        
        // 1
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {

            Helper.showAlert("Error", message: "Geofencing is not supported on this device!", viewController: self);
            return
        }
        // 2
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {

            Helper.showAlert("Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.", viewController: self);
        }
        // 3
        locationManager.startMonitoringForRegion(region)
        let messageString = "Monitoring: \(identifier) \nCordinate: \(cordinate) \nRadius: \(radius)";
        print(messageString);
        Helper.showAlert("GeoFence", message: messageString, viewController: self);
        
        
    }
    
    
    // MARK: - Notifications
    func triggerLocalNotification() -> Void {
        print("* Scheduled Local Push +10 sec");
        
        let notification = UILocalNotification()
        notification.alertBody = "Karsh says Hi";
        notification.soundName = UILocalNotificationDefaultSoundName;
        
        // Fire Date
        let fireDate = NSDate().dateByAddingTimeInterval(10);       // 10 sec from now
        notification.fireDate = fireDate;
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    /*
    var modelController: ModelController {
        // Return the model controller object, creating it if necessary.
        // In more complex implementations, the model controller may be passed to the view controller.
        if _modelController == nil {
            _modelController = ModelController()
        }
        return _modelController!
    }

    var _modelController: ModelController? = nil

    // MARK: - UIPageViewController delegate methods

    func pageViewController(pageViewController: UIPageViewController, spineLocationForInterfaceOrientation orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        if (orientation == .Portrait) || (orientation == .PortraitUpsideDown) || (UIDevice.currentDevice().userInterfaceIdiom == .Phone) {
            // In portrait orientation or on iPhone: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to true, so set it to false here.
            let currentViewController = self.pageViewController!.viewControllers![0]
            let viewControllers = [currentViewController]
            self.pageViewController!.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: {done in })

            self.pageViewController!.doubleSided = false
            return .Min
        }

        // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
        let currentViewController = self.pageViewController!.viewControllers![0] as! CameraViewController
        var viewControllers: [UIViewController]

        let indexOfCurrentViewController = self.modelController.indexOfViewController(currentViewController)
        if (indexOfCurrentViewController == 0) || (indexOfCurrentViewController % 2 == 0) {
            let nextViewController = self.modelController.pageViewController(self.pageViewController!, viewControllerAfterViewController: currentViewController)
            viewControllers = [currentViewController, nextViewController!]
        } else {
            let previousViewController = self.modelController.pageViewController(self.pageViewController!, viewControllerBeforeViewController: currentViewController)
            viewControllers = [previousViewController!, currentViewController]
        }
        self.pageViewController!.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: {done in })

        return .Mid
    }
     */

}

