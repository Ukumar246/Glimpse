//
//  LoginViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/26/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import Parse

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Public API
    var interactor:Interactor? = nil
    
    //MARK: Private API
    let SegueIdentifier_RootVC:String = "segue_LoginVC_RootVC";
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var glimpseButton: UIButton!
    
    // Constants
    let scrollViewOffset:CGPoint = CGPointMake(0, 60);
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews();
    }
    
    //MARK: - UI Setup
    /// Sets up Apperance for the Views
    func setupViews() -> Void {
        // Scroll View
        scrollView.contentSize = view.frame.size;
        scrollView.contentOffset = CGPointMake(0, 0);
        
        // Layer Setup
        glimpseButton.layer.cornerRadius = CGRectGetWidth(glimpseButton.frame) / 2;
        addBottomBorder(emailTextField);
        addBottomBorder(passwordTextField);
        
        emailTextField.text = nil;
        passwordTextField.text = nil;
        
        // Placeholders
        let attributes:[String : AnyObject] = [NSForegroundColorAttributeName : Helper.getGlimpseOrangeColor()];
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "email", attributes: attributes)
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "password", attributes: attributes);
        
        // Auto Load Email
        let (email, valid) = loadEmailTf();
        if valid{
            emailTextField.text = email;
        }
        
    }
    
    /// Adds Bottom Border to Passed Tf
    func addBottomBorder(textField:UITextField) -> Void {
        let border = CALayer()
        let width = CGFloat(2.0)
        border.borderColor = Helper.getGlimpseOrangeColor().CGColor;
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
    }
    
    /// Loads Email Based on Registered UUID
    /// Return: - Email Address: String
    ///         - Valid: Bool
    func loadEmailTf() -> (String, Bool){
        
        let uuid:String = NSUUID().UUIDString;
        
        if uuid == "e4fc45d54801309368405ae957408cf3b4fa3a78"{
            return ("karsh@a.com", true);
        }
        
        return ("Null", false);
    }
    
    // MARK: - Action
    @IBAction func tappedOutside(sender: UITapGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Recognized{
            let attachedView = sender.view
            let tappedPoint = sender.locationInView(attachedView);
            
            print("Attached View ", tappedPoint);
            
            let outside = sender.locationInView(visualEffectView);
            print("Visual View ", outside);
        }
    }
    
    @IBAction func dismissViewController(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func editingBegan(sender: UITextField) {
        if sender.tag == 1{
            if scrollView.contentOffset == CGPointMake(0, 0){
                scrollView.setContentOffset(scrollViewOffset, animated: true);
            }
        }
        else if sender.tag == 2{
            if scrollView.contentOffset == CGPointMake(0, 0){
                scrollView.setContentOffset(scrollViewOffset, animated: true);
            }
        }
    }
    
    @IBAction func loginAction(sender: UIButton) {
        print("* Logging In..");
        
        let email = emailTextField.text;
        let password = passwordTextField.text;
        
        if (email == nil || password == nil){
            return;
        }
        else if (email! == "" || password == ""){
            return;
        }
        else if (isValidEmail(email!) == false){
            // non valid email
            print("! Non valid email!");
            return;
        }
        
        login(email!, password: password!);
    }
    
    func isValidEmail(testStr:String) -> Bool {
        // println("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        scrollView.setContentOffset(CGPointMake(0, 0), animated: true);
        textField.resignFirstResponder();
        return false;
    }
    
    // MARK: - Database
    func login(username:String, password: String)
    {
        PFUser.logInWithUsernameInBackground(username, password: password){ (loggedInUser:PFUser?, error:NSError?) in
            if (error == nil && loggedInUser != nil)
            {
                // Installation
                let installation = PFInstallation.currentInstallation();
                let loggedInUser:PFUser = loggedInUser!;
                installation["user"] = loggedInUser;
                
                installation.saveInBackground();
                
                self.gotoRootViewController();
            }
            else{
                Helper.showQuickAlert("Login Failed", message: "☹️", viewController: self);
            }
        }
    }
    
    // MARK: - Navigation
    /// Enter the app
    func gotoRootViewController() -> Void {
        performSegueWithIdentifier(SegueIdentifier_RootVC, sender: nil);
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }
}
