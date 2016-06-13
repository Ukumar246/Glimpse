//
//  DataViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/18/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import Parse
import AASquaresLoading

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
    /// Segue Handler for Swipe to Dismiss
    var interactor:Interactor!
    
    // MARK: Storyboard Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var requestTextField: UITextField!
    
    @IBOutlet weak var askButton: UIButton!
    
    // MARK: Computed Properties
    var userLoggedIn:Bool{
        return (PFUser.currentUser() == nil) ? false : true;
    }
    
    var user:PFUser{
        return PFUser.currentUser()!;
    }
    
    // Constants:
    let characterLimit:Int = 40;
    let movedDownOffset:CGPoint = CGPointMake(0, -40);
    let movedUpOffset:CGPoint = CGPointZero;
    let loginSegue:String = "Segue_Login";
    
    // MARK: - Lifecycle
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
        
        // Status Bar
        UIApplication.sharedApplication().statusBarStyle = .Default;
        
        askButton.enabled = true;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        state = State(currentState: .VCLoaded);
        
        interactor = Interactor();
        
        setupViews();
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
    }
    
    /// Sets up apperance on the Storybord Views
    func setupViews() -> Void
    {
        // Status Bar
        UIApplication.sharedApplication().statusBarStyle = .Default;
        
        let defaultCornerRadius:CGFloat = 7;
        askButton.layer.cornerRadius = defaultCornerRadius;
        //subjectTextField.layer.cornerRadius = defaultCornerRadius;
        //requestTextField.layer.cornerRadius = defaultCornerRadius;
        
        askButton.layer.masksToBounds = true;
        subjectTextField.layer.masksToBounds = true;
        requestTextField.layer.masksToBounds = true;
        
        addBottomBorder(subjectTextField);
        addBottomBorder(requestTextField);
        
        askButton.enabled = true;
        
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

    // MARK: - Actions
    @IBAction func tappedScreen(sender: UITapGestureRecognizer) {
        if subjectTextField.isFirstResponder(){
            subjectTextField.resignFirstResponder();
        }
        else if requestTextField.isFirstResponder(){
            requestTextField.resignFirstResponder();
        }
    }
    
    @IBAction func tappedAsk(sender: UIButton) {
        let subject = subjectTextField.text;
        let request = requestTextField.text;
        
        if (subject == nil || request == nil)
        {
            return;
        }
        else if (subject! == "" || request! == "")
        {
            return;
        }
        else if (userLoggedIn == false){
            // User has not been logged in yet 
            //askButton.enabled = false;
            
            presentLoginScreen();
            return;
        }
        
        // Temp disable the post button
        self.askButton.enabled = false;
        
        // Dismiss Keyboards
        dismissKeyboard();
        
        postRequest(subject!, requestString: request!) { (finished) in
            self.askButton.enabled = true;
            self.clearTextFields();
        }
    }
    
    func moveUpScrollView(){
        scrollView.setContentOffset(movedUpOffset, animated: true);
    }
    
    func movedDownScrollView(){
        scrollView.setContentOffset(movedDownOffset, animated: true);
    }
    
    // MARK: - Database Operations
    /// Posts request to database 
    /// - Note:
    ///   - Blocks UI (Popup Loading Alert)
    ///   - Activates UI Activity View Etc.
    func postRequest(subjectString:String, requestString:String, completion:(finished: Bool) -> Void) -> Void
    {
        assert(PFUser.currentUser() != nil, "User must be logged in to post!");
        
        // Blocking Loading Alert
        let loadingSquare = AASquaresLoading(target: self.view, size: 40)
        loadingSquare.backgroundColor = UIColor.clearColor();
        loadingSquare.color = Helper.getGlimpseOrangeColor();
        loadingSquare.setSquareSize(120);
        loadingSquare.start()
        
        let request = PFObject(className: "Request");
        if let lastLocation = Helper.getLastKnownUserLocation(){
            request["location"] = PFGeoPoint(latitude: lastLocation.latitude, longitude: lastLocation.longitude);
        }
        else{
            print("! Warning: Posting without location data");
        }
        
        request["subject"] = subjectString;
        request["request"] = requestString;
        
        request["owner"] = user;
        request["views"] = 0;
        request["likes"] = 0;
        request.addUniqueObject(user, forKey: "followers");
    
        request.saveInBackgroundWithBlock { (success:Bool, error:NSError?) in
            
            // Unblock UI
            loadingSquare.stop();
            
            if success{
                print("* Post Uploaded Successfully!");
                // Alert then start camera again
                Helper.showQuickAlert("Posted!", message: ":)", viewController: self);
            }
            else{
                print("! Error Posting: ", error!.description);
                // Alert then start camera again
                Helper.showQuickAlert("Error!", message: error!.description, viewController: self);
            }
            
            completion(finished: true);
        }
        
        state.setState(.Posting);
    }
    
    // MARK: - TextFields
    func dismissKeyboard() -> Bool
    {
        subjectTextField.resignFirstResponder();
        requestTextField.resignFirstResponder();
        
        return true;
    }
    
    func clearTextFields()
    {
        subjectTextField.text = nil;
        requestTextField.text = nil;
        
    }
    
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
        moveUpScrollView();
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        //
        movedDownScrollView()
    }
    
    // MARK: - Navigation 
    func presentLoginScreen() -> Void
    {
        // User is NOT logged in
        performSegueWithIdentifier(loginSegue, sender: nil);
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == loginSegue)
        {
            let dvc = segue.destinationViewController as! LoginViewController;
            dvc.interactor = self.interactor;
        }
    }
}

extension CaptureViewController: UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator();
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil;
    }
}

