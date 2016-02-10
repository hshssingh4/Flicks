//
//  DetailViewController.swift
//  Flicks
//
//  Created by Harpreet Singh on 1/31/16.
//  Copyright © 2016 Harpreet Singh. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController
{

    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    
    var movie: NSDictionary!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let title = movie["title"] as? String
        titleLabel.text = title
        titleLabel.adjustsFontSizeToFitWidth = true
        
        let overview = movie["overview"] as? String
        overviewLabel.text = overview
        
        overviewLabel.sizeToFit()
        infoView.frame.size.height = overviewLabel.frame.size.height + titleLabel.frame.size.height + 25
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.size.height)

        let posterPath = movie["poster_path"] as? String
        let smallBaseUrl = "https://image.tmdb.org/t/p/w45"
        let largeBaseUrl = "https://image.tmdb.org/t/p/w342"
        
        if posterPath != nil
        {
            let smallImageUrl = NSURL(string: smallBaseUrl + posterPath!)
            let largeImageUrl = NSURL(string: largeBaseUrl + posterPath!)
            
            let smallImageRequest = NSURLRequest(URL: smallImageUrl!)
            let largeImageRequest = NSURLRequest(URL: largeImageUrl!)
            
            self.posterImageView.setImageWithURLRequest(
                smallImageRequest,
                placeholderImage: nil,
                success: {(smallImageRequest:NSURLRequest!,smallImageResponse:NSHTTPURLResponse?, smallImage:UIImage!) -> Void in

                    self.posterImageView.alpha = 0.9
                    self.posterImageView.image = smallImage
                    
                    UIView.animateWithDuration(
                        0.5,
                        animations: {
                            self.posterImageView.alpha = 1
                    },
                        completion: { (success) -> Void in
                            
                            self.posterImageView.setImageWithURLRequest(
                                largeImageRequest,
                                placeholderImage: smallImage,
                                success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                    
                                    self.posterImageView.image = largeImage
                                },
                                failure: nil)
                    })
                }, failure: nil)
        }
        else
        {
            posterImageView.image = UIImage(named: "ImageNotAvailable")
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
