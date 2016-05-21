//
//  DataViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/18/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import ALCameraViewController

class CameraViewController: UIViewController {

    var dataObject: String = ""


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let cameraVC = ALCameraViewController(croppingEnabled: false) { (finishedImage) in
            print("* Done.");
        }
        
        presentViewController(cameraVC, animated: true, completion: nil);
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }


}

