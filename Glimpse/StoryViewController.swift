//
//  StoryViewController.swift
//  Glimpse
//
//  Created by Utkarsh Kumar on 5/26/16.
//  Copyright © 2016 GlimpseCreative. All rights reserved.
//

import UIKit
import ParseUI
import Parse
import CSStickyHeaderFlowLayout

class StoryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    let ImageViewCELLTAG:Int = 1;
    
    var posts:[PFObject]?{
        didSet{
            if posts != nil{
                collectionView.reloadData();
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchPosts();
        setupViews();
    }

    // MARK: - Setup Views
    func setupViews() -> Void {
        let layout:CSStickyHeaderFlowLayout = collectionView.collectionViewLayout as! CSStickyHeaderFlowLayout;
        
        // Locate the nib and register it to your collection view
        let headerNib = UINib(nibName: "StickyHeader", bundle: nil);
        collectionView.registerNib(headerNib, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: "stickyHeader");
        
        let width = CGRectGetWidth(self.view.frame);
        layout.parallaxHeaderReferenceSize = CGSizeMake(width, 300);
    }
    
    
    // MARK: - Database Operations
    
    /// Updates Post Feed
    func fetchPosts() -> Void {
        let query = PFQuery(className: "Post");
        
        query.findObjectsInBackgroundWithBlock { (newPosts:[PFObject]?, error:NSError?) in
            print("* Found ", newPosts?.count, " Posts");
            
            if error == nil && newPosts != nil{
                self.posts = newPosts;
            }
            else{
                Helper.showQuickAlert("No Posts Found", message: "", viewController: self);
                self.posts = nil;
            }
        }
    }
    
    
    // MARK: - Collection View
    // MARK: Datasource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if posts == nil{
            return 0;
        }
        
        return posts!.count;
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        // Appearance
        let imageView = cell.viewWithTag(ImageViewCELLTAG) as! PFImageView;
        imageView.layer.cornerRadius = 7;
        imageView.layer.masksToBounds = true;
        imageView.clipsToBounds = true;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell:UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCellIdentifer", forIndexPath: indexPath);
        let imageView:PFImageView = cell.viewWithTag(ImageViewCELLTAG) as! PFImageView;
        
        let post = posts![indexPath.row]
        imageView.file = post["picture"] as? PFFile
        imageView.loadInBackground();
        
        return cell;
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var view:UICollectionReusableView!
        
        if (kind == UICollectionElementKindSectionHeader){
            view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "header", forIndexPath: indexPath);
        }
        else if (kind == CSStickyHeaderParallaxHeader){
            view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "stickyHeader", forIndexPath: indexPath)
        }
        else{
            print("Collection View Error");
        }
        
        return view;
    }
    
    // MARK: Delegates
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if posts == nil || posts?.count == 0{
            return;
        }
        print("* Selected Image", indexPath.row);
        
        // Fetch the post
        let post:PFObject = posts![indexPath.row];
        
        if let imageFile = post["picture"] as? PFFile{
            print("* File: ", imageFile);
        }
        
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
