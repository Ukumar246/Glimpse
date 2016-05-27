//
//  Helper.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/24/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import CoreLocation

// Global Data Holder
struct Global {
    static var lastUserLocation:CLLocationCoordinate2D?
    static var lastUserLocationUpdateTime:NSDate?
}

class Helper: NSObject {

    //MARK: - Alerts
    static func showAlert(title:String, message: String, viewController: UIViewController) -> Void
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert);
        let cancel = UIAlertAction(title: "Cool", style: .Cancel, handler: nil);
        alertController.addAction(cancel);
        
        viewController.presentViewController(alertController, animated: true, completion: nil);
    }
    
    static func showQuickAlert(title:String, message:String, viewController: UIViewController) ->Void
    {
        // New Alert
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert);
        viewController.presentViewController(alertController, animated: true, completion: nil);
        
        // Self Dismiss
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            alertController.dismissViewControllerAnimated(true, completion: nil);
        }
    }
    
    //MARK: - Colors
    static func getGlimpseOrangeColor() -> UIColor
    {
        //R: 234   G: 82   B:20
        return UIColor(red: 234/255, green: 82/255, blue: 20/255, alpha: 1);
    }
    
    //MARK: - Location
    static func updateLatestUserLocation(newLocation:CLLocationCoordinate2D){
        Global.lastUserLocation = newLocation;
        Global.lastUserLocationUpdateTime = NSDate();
    }
    
    static func getLastKnownUserLocation() -> CLLocationCoordinate2D?
    {
        return Global.lastUserLocation;
    }
}