//
//  Helper.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/24/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit

class Helper: NSObject {

    static func showAlert(title:String, message: String, viewController: UIViewController) -> Void
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert);
        let cancel = UIAlertAction(title: "Cool", style: .Cancel, handler: nil);
        alertController.addAction(cancel);
        
        viewController.presentViewController(alertController, animated: true, completion: nil);
    }
}
