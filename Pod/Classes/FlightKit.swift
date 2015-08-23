import KeychainAccess
import Alamofire
import SwiftyJSON
//import RZVibrantButton
import SCLAlertView

struct FlightColors {
    static var tomatoRed = UIColor(red: 172/255.0, green: 57/255.0, blue: 49/255.0, alpha: 1.0) // #AC3931
    static var darkBlue = UIColor(red: 36/255.0, green: 30/255.0, blue: 78/255.0, alpha: 1.0) // #241E4E
    static var coolYellow = UIColor(red: 214/255.0, green: 216/255.0, blue: 79/255.0, alpha: 1.0) // #D6D84F
    static var lightBlue = UIColor(red: 111/255.0, green: 138/255.0, blue: 183/255.0, alpha: 1.0) // #6F8AB7
    static var presqueWhite = UIColor(red: 251/255.0, green: 251/255.0, blue: 255/255.0, alpha: 1.0) // #FBFBFF
}

extension UIImageView {
    public func imageFromUrl(urlString: String) {
        if let url = NSURL(string: urlString) {
            let request = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                UIView.transitionWithView(self, duration: 1.0, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                    self.image = UIImage(data: data)
                }, completion: nil)
            }
        }
    }
}

public class FlightKit {

    class func loadFromNibNamed(nibNamed: String, bundle : NSBundle? = nil) -> UIView? {
        return UINib(
            nibName: nibNamed,
            bundle: bundle
            ).instantiateWithOwner(nil, options: nil)[0] as? UIView
    }
    
    class func bundle() -> NSBundle? {
        let bundle = NSBundle(forClass: self)
        let path = bundle.pathForResource("FlightKit", ofType: "bundle") as String!
        let fBundle = NSBundle(path: path)
        return fBundle;
    }
    
    public class func storyboard() -> UIStoryboard? {
        return UIStoryboard(name: "FlightKit", bundle: bundle())
    }
    
    public class func initView(from: String, to: String, label: String?, sview:UIView) {
        var view:FlightView = loadFromNibNamed("FromView", bundle:bundle()) as! FlightView;
        view.backgroundImage.image = UIImage(named: "weird_plane", inBundle: bundle(), compatibleWithTraitCollection: nil)
        view.setImageForAirport(to);
        view.requestMinPrice(from, destination: to, fromDate: NSDate(), toDate: NSDate().dateByAddingTimeInterval(30*86400))
        if let l = label {
            view.destinationLabel.text = l
        } else {
            view.destinationLabel.text = "Fly to \(to)"
        }
        view.frame = CGRectMake(0.0, 0.0, sview.bounds.width, sview.bounds.height)
        sview.addSubview(view);
    }
}

public class FlightView: UIView {

    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var effectsView: UIVisualEffectView!
    @IBOutlet weak var button: UIButton!

    var oauthToken: String!
    let keychain = Keychain(service: "io.booq").synchronizable(true)
    
    @IBAction func buttonPushed(sender: UIButton) {
        let alertView = SCLAlertView()
        
        let txt = alertView.addTextField(title: "Enter your email")
        alertView.addButton("Let me know") {
            println("let me know: \(txt.text!)")
            
            SCLAlertView().showSuccess(
                "Cool, we'll let you know",
                subTitle: "We'll monitor price changes for this flight and let you know when is the best time to buy your ticket.",
                closeButtonTitle: "Got it",
                duration: 5.0)
        }
        
        alertView.addButton("Book now") {
            println("book now")
        }

        alertView.showCloseButton = false
        
        alertView.showTitle(
            "Almost there...", // Title of view
            subTitle: "Book now or wait till the price changes?",
            duration: 0.0,
            completeText: "",
            style: .Wait,
            colorStyle: 0xAC3931,
            colorTextButton: 0xFFFFFF
        )
    }
    
    func requestSabreToken(completion: () -> Void) -> Void {
        let headers = [
            "Authorization": "Basic VmpFNk1uWjFOMmsyY1dsbGFXcGlNbW8yY1RwRVJWWkRSVTVVUlZJNlJWaFU6VXpWa05HaE5lVlk9",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        let parameters = ["grant_type": "client_credentials"]
        
        Alamofire.request(.POST, "https://api.test.sabre.com/v2/auth/token", headers: headers, parameters:parameters)
            .responseJSON { (request, response, data, error) in
                if (error != nil || JSON(data!)["error"] != nil) {
                    println(error)
                    println(JSON(data!)["error_description"])
                    completion()
                } else {
                    var json = JSON(data!)
                    println(json)
                    self.oauthToken = json["access_token"].string
                    completion()
                    println(self.oauthToken)
                    let expTime = json["expires_in"].double
                    var expDate: NSDate = NSDate().dateByAddingTimeInterval(expTime!)
                    println(expDate)
                    var data = NSKeyedArchiver.archivedDataWithRootObject(["value": self.oauthToken, "expirationDate": expDate])
                    
                    self.keychain[data: "token"] = data
                }
        }
    }
    
    func obtainSabreToken(completion: () -> Void) -> Void {
        var token = keychain[data: "token"] as NSData?
        if token == nil {
            requestSabreToken() {
                completion()
            }
        } else {
            let dtoken = NSKeyedUnarchiver.unarchiveObjectWithData(token!) as! Dictionary<String, AnyObject>
            let date = dtoken["expirationDate"] as! NSDate
            if NSDate().compare(date) == .OrderedDescending {
                requestSabreToken() {
                     completion()
                }
            } else {
                oauthToken = dtoken["value"] as! String
                completion()
            }
        }
    }
    
    public func requestMinPrice(origin: String, destination: String, fromDate: NSDate, toDate: NSDate) {
        obtainSabreToken {

            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let fromDateString = formatter.stringFromDate(fromDate)
            let toDateString = formatter.stringFromDate(toDate)
            let url = "https://api.test.sabre.com/v1.8.1/shop/calendar/flights"
            
            var json: JSON?
            
            if let path = FlightKit.bundle()!.pathForResource("post_calendar", ofType: "json") {
                if let data = NSData(contentsOfFile: path) {
                    json = JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                    
                    json!["OTA_AirLowFareSearchRQ"]["OriginDestinationInformation"][0]["DepartureDates"]["dayOrDaysRange"][0]["DaysRange"]["FromDate"].stringValue = fromDateString
                    json!["OTA_AirLowFareSearchRQ"]["OriginDestinationInformation"][0]["DepartureDates"]["dayOrDaysRange"][0]["DaysRange"]["ToDate"].stringValue = toDateString
                    
                    json!["OTA_AirLowFareSearchRQ"]["OriginDestinationInformation"][0]["OriginLocation"]["LocationCode"].stringValue = origin
                    json!["OTA_AirLowFareSearchRQ"]["OriginDestinationInformation"][0]["DestinationLocation"]["LocationCode"].stringValue = destination
                    json!["OTA_AirLowFareSearchRQ"]["OriginDestinationInformation"][1]["OriginLocation"]["LocationCode"].stringValue = destination
                    json!["OTA_AirLowFareSearchRQ"]["OriginDestinationInformation"][1]["DestinationLocation"]["LocationCode"].stringValue = origin
                }
            }
            
            let headers = [
                "Authorization": "Bearer " + self.oauthToken,
                "Content-Type": "application/json"
            ]
            
            let parameters = json!.object as! [String: AnyObject]
            
            println("jsonData:\(json!)")
            
            Alamofire.request(.POST, url, headers: headers, parameters:parameters, encoding: .JSON)
                .responseJSON { (request, response, data, error) in
                    var json = JSON(data!)
                    let price = json["OTA_AirLowFareSearchRS"]["PricedItineraries"]["PricedItinerary"][0]["AirItineraryPricingInfo"][0]["ItinTotalFare"]["TotalFare"]["Amount"].int
                    println(price)
                    
                    if let p = price {
                        self.priceLabel.text = "Starting at $\(p)"
                        
                        UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                            self.priceLabel.alpha = 1.0
                            }, completion: nil)
                    }
            }
        }
    }
    
    func commonInit() {
        obtainSabreToken(){}
    }
    
    public override func awakeFromNib() {
        self.priceLabel.alpha = 0.0
        
//        var invertButton:RZVibrantButton = RZVibrantButton(frame:CGRectZero, style:RZVibrantButtonStyle.Invert)
//        invertButton.vibrancyEffect = UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
//        invertButton.text = "Invert"
//        self.effectsView.addSubview(invertButton)
        
        commonInit()
    }
    
    public func setImageForAirport(airport: String) {
        backgroundImage.imageFromUrl("http://media.expedia.com/mobiata/mobile/apps/ExpediaBooking/FlightDestinations/images/\(airport).jpg")
    }
}