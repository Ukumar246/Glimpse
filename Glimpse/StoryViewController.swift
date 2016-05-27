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
    }

    
    // MARK: - Database Operations
    
    /// Updates Post Feed
    func fetchPosts() -> Void {
        let query = PFQuery(className: "Post");
        
        query.findObjectsInBackgroundWithBlock { (newPosts:[PFObject]?, error:NSError?) in
            if error == nil && newPosts != nil{
                self.posts = newPosts;
            }
            else{
                self.posts = nil;
            }
        }
    }
    
    
    // MARK: - Collection View
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if posts == nil{
            return 0;
        }
        
        return posts!.count;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell:UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCellIdentifer", forIndexPath: indexPath);
        let imageView:PFImageView = cell.viewWithTag(ImageViewCELLTAG) as! PFImageView;
        
        let post = posts![indexPath.row]
        imageView.file = post["picture"] as! PFFile
        imageView.loadInBackground();
        
        return cell;
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
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
