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
    static var debug:Bool?
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
        // HEX: FF8E00
        return UIColor(red: 255/255, green: 142/255, blue: 0, alpha: 1);
        //UIColor(red: 234/255, green: 82/255, blue: 20/255, alpha: 1);
    }
    
    static func getDefaultCornerRadius() -> CGFloat
    {
        return 15;
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
    
    /// Returns if Testing Mode is ON. Set value on Plist File
    static func testingOn() -> Bool
    {
        
        if  (Global.debug == nil)
        {
            let plistDictionary = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Info", ofType: "plist")!)
            let debugMode = plistDictionary?.objectForKey("debugMode") as! Bool
            
            Global.debug = debugMode
        }
        
        return Global.debug!;
    }
}
