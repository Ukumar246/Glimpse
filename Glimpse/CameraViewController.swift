//
//  CameraViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 6/16/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController, CACameraSessionDelegate {

    // MARK: Storyboard Outlets
    @IBOutlet weak var cameraViewFrame: UIView!
    var cameraView: CameraSessionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCamera();
        startCamera();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        stopCamera();
    }
    
    
    // MARK: - Camera
    func setupCamera() -> Void {
        struct Holder{
            static var called:Bool = false;
        }
        
        //assert(Holder.called == false, "Cannot Call Setup Twice");
        
        cameraView = CameraSessionView(frame: cameraViewFrame.frame);
        cameraView!.delegate = self;
        
        cameraView.layer.cornerRadius = Helper.getDefaultCornerRadius();
        cameraView.layer.masksToBounds = true;
        cameraView.clipsToBounds = true
        
        cameraViewFrame.removeFromSuperview();
        // Call Camera Public API's Here
        
        Holder.called = true;
    }
    
    func startCamera() ->Void{
        if cameraView == nil{
            setupCamera();
        }
        
        if cameraView!.hidden == true{
            // The camera view was just hidden
            cameraView!.hidden = false;
            cameraView!.alpha = 1;          // Full opacity
        }
        
        view.addSubview(cameraView!);
    }
    
    func stopCamera() -> Void{
        cameraView?.removeFromSuperview();
        cameraView = nil;
    }
    
    func didCaptureImage(image: UIImage!, withFrontCamera frontCamera: Bool) {
        
        if frontCamera{
            // Flip Image
            //            var flipedImage = UIImage(CGImage: image.CGImage!, scale: 1.0, orientation: .DownMirrored)
            //            print("* Flipped Image");
        }
        
        //previewImage(image);
        
        cameraView!.alpha = 1;          // Full opacity
        UIView.animateWithDuration(0.5, delay: 0, options: [.CurveEaseIn], animations: {
            self.cameraView!.alpha = 0;
        }) { (complete:Bool) in
            if complete{
                // Just Hide the CameraView
                self.cameraView!.hidden = true;
            }
        }
    }

    
    // MARK: - Navigation
    @IBAction func dismissViewController(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
