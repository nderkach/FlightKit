//
//  AirportSearch.swift
//  Pods
//
//  Created by Nikolay Derkach on 8/8/15.
//
//

import Foundation
import Alamofire
import SwiftyJSON

public class AirportSearch {
    public static func findAirportAtLocation(lat: Double, lon: Double, completion: (result: String) -> Void) {
        Alamofire.request(.GET, "https://booq-api.herokuapp.com/suggestNearby", headers: ["Accept": "application/json"], parameters: ["lat": String(lat), "lon": String(lon)])
            .responseJSON { _, _, json in
                let result = JSON(json.value!)["airport"].string
                completion(result: result!)
            }
    }
    
    public static func findAirportBySuggestion(query: String, completion: (results: [AnyObject]) -> Void) {
        if query == "" {
            completion(results: [])
            return
        } else {
            Alamofire.request(.GET, "https://booq-api.herokuapp.com/suggest?q=\(query)")
                .response { request, response, data, error in
                    print(request)
                    print(response)
                    print(error)
                }
                .responseJSON { _, _, json in
                    let results = JSON(json.value!)["sr"].arrayObject!
                    completion(results: results)
                }
        }
        
    }
}
