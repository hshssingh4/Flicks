//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Harpreet Singh on 1/6/16.
//  Copyright © 2016 Harpreet Singh. All rights reserved.
//

import UIKit
import AFNetworking
import SVProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var errorView: UIView!
    
    var movies: [NSDictionary]?
    var filteredData: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    let customColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1)
    let navBarColor = UIColor(red: 100.0/255.0, green: 100.0/255.0, blue: 255.0/255.0, alpha: 1)
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
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
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")
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
                            self.tableView.reloadData()
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
        tableView.insertSubview(refreshControl, atIndex: 0)
    }
    
    func onRefresh()
    {
        loadMoviesData()
        self.refreshControl.endRefreshing()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = filteredData![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
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
    
    func modifyCell(cell: MovieCell) -> MovieCell
    {
        cell.backgroundColor = customColor
        cell.titleLabel.textColor = UIColor.blackColor()
        cell.overviewLabel.textColor = UIColor.blackColor()
        cell.posterView.layer.cornerRadius = 10.0
        cell.posterView.clipsToBounds = true
        return cell
    }
    
    func modifyView()
    {
        self.searchBar.showsCancelButton = false
        self.tableView.setContentOffset(CGPoint(x: 0, y: 44), animated: true)
        self.tableView.backgroundColor = customColor
        self.navigationController?.navigationBar.barTintColor = navBarColor
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
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
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        self.searchBar.endEditing(true)
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar)
    {
        tableView.insertSubview(refreshControl, atIndex: 0)
        self.searchBar.endEditing(true)
        self.searchBar.text = ""
        self.searchBar(searchBar, textDidChange: self.searchBar.text!)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar)
    {
        self.refreshControl.removeFromSuperview()
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar)
    {
        self.searchBar.showsCancelButton = false
    }
    
    @IBAction func closeErrorView(sender: UIButton)
    {
        errorView.hidden = true
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
