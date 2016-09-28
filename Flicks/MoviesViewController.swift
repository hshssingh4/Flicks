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

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var movies: [NSDictionary]?
    var filteredData: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var collectionViewRefreshControl: UIRefreshControl!
    var endpoint: String!
    let customColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1)
    let navBarColor = UIColor(red: 100.0/255.0, green: 100.0/255.0, blue: 255.0/255.0, alpha: 1)
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.delegate = self
        errorView.isHidden = true
        SVProgressHUD.show()
        loadMoviesData()
        SVProgressHUD.dismiss()
        addRefreshControl()
        modifyView()
        hideCollectionView()
    }
    
    func loadMoviesData()
    {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string:"https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        let task : URLSessionDataTask = session.dataTask(with: request,
            completionHandler: { (dataOrNil, response, error) in
                if error == nil
                {
                    self.errorView.isHidden = true
                    self.searchBar.isUserInteractionEnabled = true
                    if let data = dataOrNil
                    {
                        if let responseDictionary = try! JSONSerialization.jsonObject(
                            with: data, options:[]) as? NSDictionary
                        {
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredData = self.movies
                            self.tableView.reloadData()
                            self.collectionView.reloadData()
                        }
                    }
                }
                else
                {
                    self.errorView.isHidden = false
                    self.searchBar.isUserInteractionEnabled = false
                    
                }
        });
        task.resume()
    }
    
    func addRefreshControl()
    {
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.black
        refreshControl.addTarget(self, action: #selector(MoviesViewController.onRefresh), for: UIControlEvents.valueChanged)
        collectionViewRefreshControl = UIRefreshControl()
        collectionViewRefreshControl.tintColor = UIColor.black
        collectionViewRefreshControl.addTarget(self, action: #selector(MoviesViewController.onRefresh), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
        collectionView.insertSubview(collectionViewRefreshControl, at: 0)
    }
    
    func onRefresh()
    {
        loadMoviesData()
        self.refreshControl.endRefreshing()
        self.collectionViewRefreshControl.endRefreshing()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        let movie = filteredData![(indexPath as NSIndexPath).row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        let posterPath = movie["poster_path"] as? String
        let baseUrl = "https://image.tmdb.org/t/p/w342"
        
        if posterPath != nil
        {
            let imageUrl = URL(string: baseUrl + posterPath!)
            //cell.posterView.setImageWithURL(imageUrl!)
            
            let request = URLRequest(url: imageUrl!)
            cell.posterView.setImageWith(request, placeholderImage: nil, success: {(request:URLRequest!,response:HTTPURLResponse?, image:UIImage!) -> Void in
                if response != nil
                {
                    cell.posterView.alpha = 0
                    cell.posterView.image = image
                    UIView.animate(withDuration: 1.0, animations:
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
    
    func modifyCell(_ cell: MovieCell) -> MovieCell
    {
        cell.backgroundColor = customColor
        cell.titleLabel.textColor = UIColor.black
        cell.titleLabel.adjustsFontSizeToFitWidth = true
        cell.overviewLabel.textColor = UIColor.black
        cell.posterView.clipsToBounds = true
        return cell
    }
    
    func modifyCollectionCell(_ cell: CollectionViewCell) -> CollectionViewCell
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
        self.tableView.backgroundColor = customColor
        self.navigationController?.navigationBar.barTintColor = navBarColor
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Search bar functions.
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
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
                if ((value["title"] as! String).uppercased()).contains(searchText.uppercased())
                {
                    data.append(value)
                }
            }
        }
        
        filteredData = data
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.searchBar.endEditing(true)
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        tableView.insertSubview(refreshControl, at: 0)
        collectionView.insertSubview(collectionViewRefreshControl, at: 0)
        self.searchBar.endEditing(true)
        self.searchBar.text = ""
        self.searchBar(searchBar, textDidChange: self.searchBar.text!)
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        self.refreshControl.removeFromSuperview()
        self.collectionViewRefreshControl.removeFromSuperview()
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        self.searchBar.showsCancelButton = false
    }
    
    @IBAction func closeErrorView(_ sender: UIButton)
    {
        errorView.isHidden = true
    }
    
    // Sort Methods
    
    @IBAction func sortObjects(_ sender: AnyObject)
    {
        let alert = UIAlertController(title: "Sort", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // Four Actions Added.
        alert.addAction(UIAlertAction(title: "Ascending (Title)", style: UIAlertActionStyle.default, handler: sortAscending))
        alert.addAction(UIAlertAction(title: "Descending (Title)", style: UIAlertActionStyle.default, handler: sortDescending))
        alert.addAction(UIAlertAction(title: "Original", style: UIAlertActionStyle.default, handler: sortOriginal))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: nil))
    
        // Disable Originial if search bar is enabled.
        /*if (searchBar.isFirstResponder())
        {
            alert.actions[2].enabled = false
        }*/
        
        // Present the Alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func sortAscending(_ alert: UIAlertAction!)
    {
        filteredData?.sort {
            item1, item2 in
            let movietitle1 = item1["title"] as! String
            let movietitle2 = item2["title"] as! String
            return movietitle2 > movietitle1
        }
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    func sortDescending(_ alert: UIAlertAction!)
    {
        filteredData?.sort {
            item1, item2 in
            let movietitle1 = item1["title"] as! String
            let movietitle2 = item2["title"] as! String
            return movietitle1 > movietitle2
        }
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    func sortOriginal(_ alert: UIAlertAction!)
    {
        filteredData = movies
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    // Collection View Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! CollectionViewCell
        let movie = filteredData![(indexPath as NSIndexPath).row]
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
            let imageUrl = URL(string: baseUrl + posterPath!)
            //cell.posterView.setImageWithURL(imageUrl!)
            
            let request = URLRequest(url: imageUrl!)
            cell.posterView.setImageWith(request, placeholderImage: nil, success: {(request:URLRequest!,response:HTTPURLResponse?, image:UIImage!) -> Void in
                if response != nil
                {
                    cell.posterView.alpha = 0
                    cell.posterView.image = image
                    UIView.animate(withDuration: 1.0, animations:
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
        
        let newCell = modifyCollectionCell(cell)
        return newCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.lightGray
        UIView.animate(withDuration: 0.3, animations: {
            cell?.backgroundColor = self.customColor
        })
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
    {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.lightGray
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
    {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = customColor
    }

    //Show/Hide Collection View and Table View
    @IBAction func switchViews(_ sender: AnyObject)
    {
        if(collectionView.isHidden)
        {
            hideTableView()
        }
        else
        {
            hideCollectionView()
        }
    }
    
    func hideTableView()
    {
        UIView.transition(from: tableView, to: collectionView, duration: 1.0, options: UIViewAnimationOptions.showHideTransitionViews, completion: nil)
        navigationItem.leftBarButtonItem?.image = UIImage(named: "TitleViewIcon")
    }
    
    func hideCollectionView()
    {
        UIView.transition(from: collectionView, to: tableView, duration: 1.0, options: UIViewAnimationOptions.showHideTransitionViews, completion: nil)
        navigationItem.leftBarButtonItem?.image = UIImage(named: "CollectionViewIcon")
    }

        
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let cell = sender as? UITableViewCell
        {
            let indexPath = tableView.indexPath(for: cell)
            let movie = filteredData![(indexPath! as NSIndexPath).row]
            let detailViewController = segue.destination as! DetailViewController
            
            detailViewController.movie = movie
        }
        else if let cell = sender as? UICollectionViewCell
        {
            let indexPath = collectionView.indexPath(for: cell)
            let movie = filteredData![(indexPath! as NSIndexPath).row]
            let detailViewController = segue.destination as! DetailViewController
            
            detailViewController.movie = movie
        }
    }
}
