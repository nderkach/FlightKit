//
//  AirportSearch.swift
//  Pods
//
//  Created by Nikolay Derkach on 8/8/15.
//
//

import Foundation
import Alamofire

public class AirportSearch {
    public static func findAirportAtLocation(lat: Double, long: Double) {
        Alamofire.request(.GET, "https://suggest.expedia.com/hint/es/v1/nearby/en_US", headers: ["Accept": "application/json"], parameters: ["siteid": "1", "latlong": "\(lat)|\(long)", "maxresults": "20", "type": "65", "maxradius": "50", "sort": "p"])
            .response { request, response, data, error in
                println(request)
                println(response)
                println(error)
            }
            .responseJSON { _, _, JSON, _ in
                let results = JSON!.valueForKey("r") as! [AnyObject]
                println(results[0].valueForKey("s") as! String)
        }
    }
    
    public static func findAirportBySuggestion(query: String, completion: (results: [AnyObject]) -> Void) {
        if query == "" {
            completion(results: [])
            return
        } else {
            Alamofire.request(.GET, "https://suggest.expedia.com/hint/es/v2/ac/en_US/\(query)", headers: ["Accept": "application/json"], parameters: ["type": "95", "lob": "Flights"])
                .response { request, response, data, error in
                    println(request)
                    println(response)
                    println(error)
                }
                .responseJSON { _, _, JSON, _ in
                    if let results = JSON?.valueForKey("sr") as? [AnyObject] {
                        completion(results: results)
                    } else {
                        completion(results: [])
                    }
            }
        }
    }
}
