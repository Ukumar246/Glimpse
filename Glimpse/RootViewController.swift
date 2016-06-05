//
//  RootViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/18/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import CoreLocation
import EZSwipeController
import Parse

class RootViewController: EZSwipeController, CLLocationManagerDelegate, EZSwipeControllerDataSource {

    //var pageViewController: UIPageViewController?

    //MARK: Private API
    // Location
    var locationManager:CLLocationManager!
    var monitorLocation:CLLocationCoordinate2D?{
        didSet{
            print("* GeoFence Area Set.");
            //startMonitoringGeotification(locValue, radius: 100, identifier: "THOT");
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocationManager();
        
        // Monitor Location Setup
        monitorLocation = nil;
    }
   
    
    // MARK: - EZ Swipe View Controller
    override func setupView() {
        super.setupView()
        navigationBarShouldNotExist = true;
        datasource = self
    }
    
    func viewControllerData() -> [UIViewController] {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil);
        
        let captureVC:UIViewController = storyBoard.instantiateViewControllerWithIdentifier("CaptureViewController");
        let storyVC:UIViewController = storyBoard.instantiateViewControllerWithIdentifier("StoryNavigationViewController");
        let profileVC:UIViewController = storyBoard.instantiateViewControllerWithIdentifier("ProfileNavigationViewController");
        
        return [storyVC, captureVC, profileVC];
    }
    
    func indexOfStartingPage() -> Int {
        return 1;
    }
    
    func changedToPageIndex(index: Int) {
        print("* Swiped to index", index);
    }
    
    
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
        
        Helper.updateLatestUserLocation(locValue);
        
        // run only once
        if monitorLocation == nil{
            monitorLocation = locValue
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
}

