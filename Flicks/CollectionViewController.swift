//
//  CollectionViewController.swift
//  Flicks
//
//  Created by Harpreet Singh on 1/13/16.
//  Copyright © 2016 Harpreet Singh. All rights reserved.
//

import UIKit
import AFNetworking
import SVProgressHUD

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var movies: [NSDictionary]?
    var filteredData: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var endpoint: String!
    let customColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1)
    let navBarColor = UIColor(red: 100.0/255.0, green: 100.0/255.0, blue: 255.0/255.0, alpha: 1)
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.delegate = self
        errorView.hidden = true
        SVProgressHUD.show()
        loadMoviesData()
        SVProgressHUD.dismiss()
        addRefreshControl()
        modifyView()
    }
    
    func loadMoviesData()
    {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                if error == nil
                {
                    self.errorView.hidden = true
                    self.searchBar.userInteractionEnabled = true
                    if let data = dataOrNil
                    {
                        if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                            data, options:[]) as? NSDictionary
                        {
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredData = self.movies
                            self.collectionView.reloadData()
                        }
                    }
                }
                else
                {
                    self.errorView.hidden = false
                    self.searchBar.userInteractionEnabled = false
                }
        });
        task.resume()
    }
    
    func addRefreshControl()
    {
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.blackColor()
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.insertSubview(refreshControl, atIndex: 0)
    }
    
    func onRefresh()
    {
        loadMoviesData()
        self.refreshControl.endRefreshing()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if let filteredData = filteredData
        {
            return filteredData.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionCell", forIndexPath: indexPath) as! CollectionViewCell
        let movie = filteredData![indexPath.row]
        let release = movie["release_date"] as! String
        let rating = String(movie["vote_average"] as! Double)
        let title = movie["title"] as! String
        cell.titleLabel.text = title
        cell.releaseLabel.text = release
        cell.ratingLabel.text = rating
        
        let posterPath = movie["poster_path"] as? String
        let baseUrl = "https://image.tmdb.org/t/p/w342"
        
        if posterPath != nil
        {
            let imageUrl = NSURL(string: baseUrl + posterPath!)
            //cell.posterView.setImageWithURL(imageUrl!)
            
            let request = NSURLRequest(URL: imageUrl!)
            cell.posterView.setImageWithURLRequest(request, placeholderImage: nil, success: {(request:NSURLRequest!,response:NSHTTPURLResponse?, image:UIImage!) -> Void in
                if response != nil
                {
                    cell.posterView.alpha = 0
                    cell.posterView.image = image
                    UIView.animateWithDuration(1.0, animations:
                        {
                            cell.posterView.alpha = 1
                    })
                }
                else
                {
                    cell.posterView.image = image
                }
                }, failure: nil)
        }
        else
        {
            cell.posterView.image = UIImage(named: "ImageNotAvailable")
        }
        
        let newCell = modifyCell(cell)
        return newCell
    }
    
    func modifyCell(cell: CollectionViewCell) -> CollectionViewCell
    {
        cell.backgroundColor = customColor
        cell.releaseLabel.backgroundColor = collectionView.backgroundColor
        cell.releaseLabel.layer.masksToBounds = true
        cell.releaseLabel.layer.cornerRadius = 10.0
        cell.ratingLabel.backgroundColor = collectionView.backgroundColor
        cell.ratingLabel.layer.masksToBounds = true
        cell.ratingLabel.layer.cornerRadius = 10.0
        return cell
    }

    func modifyView()
    {
        self.searchBar.showsCancelButton = false
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.navigationBar.barTintColor = navBarColor
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor.lightGrayColor()
        UIView.animateWithDuration(0.3, animations: {
            cell?.backgroundColor = self.customColor
        })
        
    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath)
    {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor.lightGrayColor()
    }
    
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath)
    {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = customColor
    }
    
    // Search bar functions.
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
    {
        var data = [NSDictionary]()
        
        if searchText.isEmpty
        {
            data = movies!
        }
        else
        {
            for value in movies!
            {
                if ((value["title"] as! String).uppercaseString).containsString(searchText.uppercaseString)
                {
                    data.append(value)
                }
            }
        }
        
        filteredData = data
        collectionView.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        self.searchBar.endEditing(true)
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar)
    {
        collectionView.insertSubview(refreshControl, atIndex: 0)
        self.searchBar.endEditing(true)
        self.searchBar.text = ""
        self.searchBar(searchBar, textDidChange: self.searchBar.text!)
        self.navigationItem.rightBarButtonItem?.enabled = true
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar)
    {
        self.refreshControl.removeFromSuperview()
        self.searchBar.showsCancelButton = true
        self.navigationItem.rightBarButtonItem?.enabled = false
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar)
    {
        self.searchBar.showsCancelButton = false
    }
    
    @IBAction func closeErrorView(sender: UIButton)
    {
        errorView.hidden = true
    }
    
    // Sort Methods
    
    @IBAction func sortObjects(sender: AnyObject)
    {
        let alert = UIAlertController(title: "Sort", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        // Four Actions Added.
        alert.addAction(UIAlertAction(title: "Ascending (Title)", style: UIAlertActionStyle.Default, handler: sortAscending))
        alert.addAction(UIAlertAction(title: "Descending (Title)", style: UIAlertActionStyle.Default, handler: sortDescending))
        alert.addAction(UIAlertAction(title: "Original", style: UIAlertActionStyle.Default, handler: sortOriginal))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil))
        
        // Disable Originial if search bar is enabled.
        /*if (searchBar.isFirstResponder())
        {
        alert.actions[2].enabled = false
        }*/
        
        // Present the Alert.
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func sortAscending(alert: UIAlertAction!)
    {
        filteredData?.sortInPlace {
            item1, item2 in
            let movietitle1 = item1["title"] as! String
            let movietitle2 = item2["title"] as! String
            return movietitle2 > movietitle1
        }
        collectionView.reloadData()
    }
    
    func sortDescending(alert: UIAlertAction!)
    {
        filteredData?.sortInPlace {
            item1, item2 in
            let movietitle1 = item1["title"] as! String
            let movietitle2 = item2["title"] as! String
            return movietitle1 > movietitle2
        }
        collectionView.reloadData()
    }
    
    func sortOriginal(alert: UIAlertAction!)
    {
        filteredData = movies
        collectionView.reloadData()
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let cell = sender as? UICollectionViewCell
        {
            let indexPath = collectionView.indexPathForCell(cell)
            let movie = filteredData![indexPath!.row]
            let detailViewController = segue.destinationViewController as! DetailViewController
            
            detailViewController.movie = movie
        }
    }
    

}
