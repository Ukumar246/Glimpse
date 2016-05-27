//
//  AppDelegate.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/18/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import ALCameraViewController
import Parse
import Bolts

enum GeoEventType {
    case ENTER, EXIT;
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?

    //MARK: Private API
    let parseApplicationID:String = "0R6LwrHMNcPYkNbXZ7Opm6W34am82n0x2r49Xhg0";
    let parseClientKey:String = "vLSh8NnLzqIvrF8FFIs3KczyIBF8PX6mJo7NzUeF";

    var locationManager:CLLocationManager!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Parse Config
        Parse.enableLocalDatastore();
        
        // Initialize Parse.
        Parse.setApplicationId(parseApplicationID, clientKey: parseClientKey)
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        // Register for Push Notitications
        if application.applicationState != UIApplicationState.Background
        {
            let preBackgroundPush = !application.respondsToSelector("backgroundRefreshStatus")
            let oldPushHandlerOnly = !self.respondsToSelector("application:didReceiveRemoteNotification:fetchCompletionHandler:")
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
        if application.respondsToSelector("registerUserNotificationSettings:")
        {
            let setting = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            application.registerUserNotificationSettings(setting)
            application.registerForRemoteNotifications()
        }
        else
        {
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil));
            UIApplication.sharedApplication().cancelAllLocalNotifications()
        }
        
        
        // Location Manager
        locationManager = CLLocationManager();
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization();
        
        
        // Parse User Login
        if PFUser.currentUser() == nil{
            // User is NOT logged in
            let storyBoard = UIStoryboard(name: "Main", bundle: nil);
            let loginVC:LoginViewController = storyBoard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController;
            
            
            window?.rootViewController = loginVC;
            window?.makeKeyAndVisible();
        }
        
        return true
    }

    // MARK: - Location 
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleRegionEvent(region, type: .ENTER);
        }
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleRegionEvent(region, type: .EXIT);
        }
    }
    func handleRegionEvent(region: CLRegion!, type:GeoEventType) {
        print("////// GEO FENCE TRIGGERED ////////");
        // Show an alert if application is active
        if UIApplication.sharedApplication().applicationState == .Active {
            if let viewController = window?.rootViewController {
                Helper.showAlert("Geo Fence Triggered", message: "You \(type) the area", viewController: viewController);
            }
        }
        else {
            // Otherwise present a local notification
            let notification = UILocalNotification()
            notification.alertBody = "Geo Fence Triggered";
            notification.soundName = "Default";
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }
    
    
    // MARK: - APP Status Change Methods
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    // MARK: - Notifications
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print("Got Local notification :)");
    }
    
    //MARK: Notifications
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        /*  .......   General Handler for Parse CUSTOM  PUSH  .......   */
        
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)                            // Set Device Token
        
        // Add to Master Channel
        installation.addUniqueObject("global", forKey: "channels");
        installation.saveEventually();
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void)
    {
            PFPush.handlePush(userInfo)
            completionHandler(UIBackgroundFetchResult.NewData)
            
            if application.applicationState == UIApplicationState.Inactive{
                PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
            }
        return;
    }
}

