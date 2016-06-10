//
//  DataViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/18/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import Parse

enum VCState {
    case VCLoaded, Typing ,Posting;
}

struct State {
    /// Last system time this stuct was modifed
    var lastModified:NSDate!
    /// Current state of the view controller
    var currentState:VCState!{
        didSet{
            lastModified = NSDate();
        }
    };
    
    init(currentState: VCState) {
        self.currentState = currentState;
    }
    
    mutating func setState(newState: VCState){
        self.currentState = newState;
    }
}


class CaptureViewController: UIViewController, UITextFieldDelegate
{
    //MARK: Private API
    
    /// The state the view controller is currently in
    var state:State!
    
    // MARK: Storyboard Outlets
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var requestTextField: UITextField!
    
    @IBOutlet weak var askButton: UIButton!
    
    var user:PFUser{
        return PFUser.currentUser()!;
    }
    
    // Constants:
    let characterLimit:Int = 40;
    
    // MARK: - Lifecycle
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (state.currentState == .Typing){
            // Dont Do Anything
        }
        else if (state.currentState == .Posting){
            // Dont Do Anything
        }
        else{
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        state = State(currentState: .VCLoaded);
        
        
        setupViews();
    }

    /// Sets up apperance on the Storybord Views
    func setupViews() -> Void
    {
        let defaultCornerRadius:CGFloat = 7;
        askButton.layer.cornerRadius = defaultCornerRadius;
        //subjectTextField.layer.cornerRadius = defaultCornerRadius;
        //requestTextField.layer.cornerRadius = defaultCornerRadius;
        
        askButton.layer.masksToBounds = true;
        subjectTextField.layer.masksToBounds = true;
        requestTextField.layer.masksToBounds = true;
        
        addBottomBorder(subjectTextField);
        addBottomBorder(requestTextField);
        
        let _:[String: AnyObject] = [NSForegroundColorAttributeName: Helper.getGlimpseOrangeColor()];
    }
    
    // Adds Bottom Border to Passed Tf
    func addBottomBorder(textField:UITextField) -> Void {
        let border = CALayer()
        let width = CGFloat(2.0)
        border.borderColor = Helper.getGlimpseOrangeColor().CGColor;
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
    }

    
    @IBAction func tappedScreen(sender: UITapGestureRecognizer) {
        
    }
    
    // MARK: - Database Operations
    func postRequestToParse(comment:String) -> Void {
        
        let request = PFObject(className: "Post");
        
        if let lastLocation = Helper.getLastKnownUserLocation(){
            request["location"] = PFGeoPoint(latitude: lastLocation.latitude, longitude: lastLocation.longitude);
        }
        else{
            print("!! Error: Cannot determine location :(");
            return;
        }
        request["comment"] = comment;
        request["user"] = user;
        request["views"] = 0;
        request["viewers"] = [];
        
        request.saveInBackgroundWithBlock { (success:Bool, error:NSError?) in
            
            if success{
                print("* Post Uploaded Successfully!");
                // Alert then start camera again
                Helper.showQuickAlert("Posted!", message: "Check your feed", viewController: self);
            }
            else{
                print("! Error Posting: ", error!.description);
                // Alert then start camera again
                Helper.showQuickAlert("Error!", message: error!.description, viewController: self);
            }
            
            // After Posting
        }
        
        state.setState(.Posting);
    }
    
    // MARK: - Actions
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= characterLimit
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.attributedPlaceholder = nil;
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.text == nil || textField.text == ""{
            // Insert attributed placeholder in here
            //            textField.attributedPlaceholder
        }
    }
}

