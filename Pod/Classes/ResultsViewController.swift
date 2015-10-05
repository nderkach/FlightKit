//
//  ResultsViewController.swift
//  Pods
//
//  Created by Nikolay Derkach on 10/4/15.
//
//

import UIKit
import Alamofire
import SwiftyJSON

class ResultsViewController: UITableViewController {
    
    var fromAirport: String?
    var toAirport: String?
    var departDate: NSDate?
    
    var results: [JSON]? = [] {
        didSet {
            if let _ = self.results {
                self.tableView.reloadData()
            }
        }
    }
    
    var backgroundView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView.frame = self.tableView.frame
        self.tableView.backgroundView = backgroundView
        self.tableView.tableFooterView = UIView(frame: CGRectZero)

        print("load")
        self.setImageForAirport(toAirport!)
        SwiftSpinner.show("Connecting to satellite...")
        
        print(self.fromAirport, self.toAirport, self.departDate)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        let departDateString = dateFormatter.stringFromDate(departDate!)

        Alamofire.request(.GET, "https://booq-api.herokuapp.com/search", headers: ["Accept": "application/json"], parameters: ["departureAirport": self.fromAirport!, "arrivalAirport": self.toAirport!, "departureDate": departDateString])
            .responseJSON { (_, _, data) in
                if (data.isFailure) {
                    print("error")
                } else {
                    self.results = JSON(data.value!).array
                    print(self.results)
                    SwiftSpinner.hide()
                }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func setImageForAirport(airport: String) {
        backgroundView.imageFromUrl(("https://media.expedia.com/mobiata/mobile/apps/ExpediaBooking/FlightDestinations/images/\(airport).jpg"))
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ResultCell") as! ResultsTableViewCell
        cell.priceLabel.text = self.results![indexPath.row]["totalFarePrice"]["formattedPrice"].stringValue
        cell.typeLabel.text = self.results![indexPath.row]["type"].stringValue
                
        return cell;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let results = self.results {
            return results.count
        } else {
            return 0
        }
            
    }
}

public class ResultsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!

    var visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark)) as UIVisualEffectView
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        self.visualEffectView.frame = self.frame
        self.insertSubview(self.visualEffectView, atIndex: 0)
    }
}

