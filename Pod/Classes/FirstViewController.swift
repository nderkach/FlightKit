//
//  FirstViewController.swift
//  Pods
//
//  Created by Nikolay Derkach on 8/7/15.
//
//

import UIKit
import CoreLocation
//import RZVibrantButton
import FlightKit

class FirstViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    
    @IBOutlet weak var effectsView: UIVisualEffectView!
    
    @IBOutlet weak var toTextField: AirportTextField!
    var locationManager = CLLocationManager()
    var airports = [String]()
    var location: CLLocation?
    var completionResults = [AnyObject]()
    var toAirport: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        var translucentButton:RZVibrantButton = RZVibrantButton(frame:CGRectZero)
//        translucentButton.vibrancyEffect = UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
//        translucentButton.text = "Translucent";
//        effectsView.contentView.addSubview(translucentButton)
        
        toTextField.borderActiveColor = FlightColors.tomatoRed
        toTextField.borderInactiveColor = FlightColors.coolYellow
        toTextField.placeholderColor = FlightColors.presqueWhite.colorWithAlphaComponent(0.8)
        
        toTextField.autoCompleteTextColor = FlightColors.presqueWhite.colorWithAlphaComponent(0.8)
        toTextField.autoCompleteTextFont = toTextField.font.fontWithSize(15.0)
        
        toTextField.onSelect = {[weak self] text, indexpath in
            self!.toTextField.resignFirstResponder()
            let d = self!.completionResults[indexpath.row] as! NSDictionary
            self!.toAirport = d["a"] as? String
            var name = text.componentsSeparatedByString(",")[0] as String!
            self!.toTextField.text = "\(name) (\(self!.toAirport!))"
            println(self!.toAirport)
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let d = completionResults[0] as? NSDictionary {
            self.toAirport = d["a"] as? String
            var name = (d["l"] as? String)!.componentsSeparatedByString(",")[0] as String!
            self.toTextField.text = "\(name) (\(self.toAirport!))"
            println(self.toAirport)
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.toTextField.hideAutoCompleteTableView()
        })
        
        textField.resignFirstResponder()
        
        return false
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
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
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("locations = \(locationManager)")
        self.location = locationManager.location;
//        var latValue = locationManager.location.coordinate.latitude
//        var lonValue = locationManager.location.coordinate.longitude
//        println("\(latValue), \(lonValue)")
//        
//        AirportSearch.findAirportAtLocation(Double(latValue), long: Double(lonValue))
        
        locationManager.stopUpdatingLocation()
    }
}
