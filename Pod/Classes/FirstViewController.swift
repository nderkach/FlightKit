//
//  FirstViewController.swift
//  Pods
//
//  Created by Nikolay Derkach on 8/7/15.
//
//

import UIKit
import CoreLocation

class FirstViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, CVCalendarViewDelegate, CVCalendarMenuViewDelegate {
    
    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    
    @IBOutlet weak var monthLabel: UILabel!
    
    var calendarAnimationFinished = true
    
    @IBOutlet weak var toTextField: AirportTextField!
    var locationManager = CLLocationManager()
    var airports = [String]()
    var location: CLLocation?
    var completionResults = [AnyObject]()
    var fromAirport: String?
    var toAirport: String?
    var departDate: NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        monthLabel.text = CVDate(date: NSDate()).globalDescription
        
//        var translucentButton:RZVibrantButton = RZVibrantButton(frame:CGRectZero)
//        translucentButton.vibrancyEffect = UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
//        translucentButton.text = "Translucent";
//        effectsView.contentView.addSubview(translucentButton)
        
        toTextField.borderActiveColor = FlightColors.tomatoRed
        toTextField.borderInactiveColor = FlightColors.coolYellow
        toTextField.placeholderColor = FlightColors.presqueWhite.colorWithAlphaComponent(0.8)
        
        toTextField.autoCompleteTextColor = FlightColors.presqueWhite.colorWithAlphaComponent(0.8)
        toTextField.autoCompleteTextFont = toTextField.font!.fontWithSize(15.0)
        
        toTextField.onSelect = {[weak self] text, indexpath in
            self!.toTextField.resignFirstResponder()
            let d = self!.completionResults[indexpath.row] as! NSDictionary
            self!.toAirport = d["a"] as? String
            let name = text.componentsSeparatedByString(",")[0] as String!
            self!.toTextField.text = "\(name) (\(self!.toAirport!))"
            print(self!.toAirport)
        }
        
        toTextField.onTextChange = { [weak self] text in
            AirportSearch.findAirportBySuggestion(text) {
                (results: [AnyObject]) in
                if results.count > 0 {
                    var locations = [String]()
                    for dict in results as! [NSDictionary] {
                        locations.append(dict["l"] as! String)
                    }
                    self!.toTextField.autoCompleteStrings = locations
                    self!.completionResults = results
                } else {
                    self!.toTextField.autoCompleteStrings = nil
                }
            }
        }
        
        locationManager.delegate = self;
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        calendarView.commitCalendarViewUpdate()
        menuView.commitMenuViewUpdate()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // TMP!
        self.toAirport = "FRA"
        self.fromAirport = "SEA"
        self.departDate = NSDate().dateByAddingTimeInterval(6*24*3600)
        performSegueWithIdentifier("showResultsSegue", sender: self)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let d = completionResults[0] as? NSDictionary {
            self.toAirport = d["a"] as? String
            let name = (d["l"] as? String)!.componentsSeparatedByString(",")[0] as String!
            self.toTextField.text = "\(name) (\(self.toAirport!))"
            print(self.toAirport)
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.toTextField.hideAutoCompleteTableView()
        })
        
        textField.resignFirstResponder()
        
        return false
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            let alertController = UIAlertController(
                title: "Background Location Access Disabled",
                message: "In order to be notified about adorable kittens near you, please open this app's settings and set location access to 'Always'.",
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locations = \(locationManager)")
        self.location = locationManager.location;
        let latValue = locationManager.location!.coordinate.latitude
        let lonValue = locationManager.location!.coordinate.longitude
        print("\(latValue), \(lonValue)")

        AirportSearch.findAirportAtLocation(Double(latValue), lon: Double(lonValue)) {
            (result: String) in
            self.fromAirport = result
            print(result)
        }
        
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CVCalendarViewDelegate & CVCalendarMenuViewDelegate
    
    /// Required method to implement!
    func presentationMode() -> CalendarMode {
        return .MonthView
    }
    
    /// Required method to implement!
    func firstWeekday() -> Weekday {
        return .Sunday
    }
    
    func presentedDateUpdated(date: CVDate) {
        if monthLabel.text != date.globalDescription && self.calendarAnimationFinished {
            let updatedMonthLabel = UILabel()
            updatedMonthLabel.textColor = monthLabel.textColor
            updatedMonthLabel.font = monthLabel.font
            updatedMonthLabel.textAlignment = .Center
            updatedMonthLabel.text = date.globalDescription
            updatedMonthLabel.sizeToFit()
            updatedMonthLabel.alpha = 0
            updatedMonthLabel.center = self.monthLabel.center
            
            let offset = CGFloat(48)
            updatedMonthLabel.transform = CGAffineTransformMakeTranslation(0, offset)
            updatedMonthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
            
            UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.calendarAnimationFinished = false
                self.monthLabel.transform = CGAffineTransformMakeTranslation(0, -offset)
                self.monthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
                self.monthLabel.alpha = 0
                
                updatedMonthLabel.alpha = 1
                updatedMonthLabel.transform = CGAffineTransformIdentity
                
                }) { _ in
                    
                    self.calendarAnimationFinished = true
                    self.monthLabel.frame = updatedMonthLabel.frame
                    self.monthLabel.text = updatedMonthLabel.text
                    self.monthLabel.transform = CGAffineTransformIdentity
                    self.monthLabel.alpha = 1
                    updatedMonthLabel.removeFromSuperview()
            }
            
            self.view.insertSubview(updatedMonthLabel, aboveSubview: self.monthLabel)
        }
    }
    
    func didSelectDayView(dayView: CVCalendarDayView) {
        self.departDate = dayView.date.convertedDate()
        print("\(calendarView.presentedDate.commonDescription) is selected!")
        performSegueWithIdentifier("showResultsSegue", sender: self)
    }
    
    func shouldShowWeekdaysOut() -> Bool {
        return true
    }
    
    @IBAction func loadNext(sender: AnyObject) {
        calendarView.loadNextView()
    }
    
    @IBAction func loadPrevious(sender: AnyObject) {
        calendarView.loadPreviousView()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showResultsSegue" {
            let dc = segue.destinationViewController as! ResultsViewController
            dc.departDate = self.departDate
            dc.fromAirport = self.fromAirport
            dc.toAirport = self.toAirport
        }
    }
}
