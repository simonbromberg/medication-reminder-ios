//
//  NetworkManager.swift
//  medication-reminder
//
//  Created by Simon Bromberg on 2017-06-07.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct APIConstant {
    static let baseURL = "http://localhost:9000/api/"
    static let medication = "medications"
    
    static let startParameter = "start="
    static let endParameter = "end="
    static let dateFormat = "MM/dd/yyyy"
    
    static var medicationEndpoint: String {
        return baseURL + medication
    }
    
    static let JSONDateFormat = "yyyy-MM-dd'T'HH:mm:ssz"
}

class NetworkManager {
    static let sharedInstance = NetworkManager()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = APIConstant.dateFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        return formatter
    }()
    
    private var todaysMedicationsEndpoint: String {
        let range = NetworkManager.todayDateRange
        
        let startTime = dateFormatter.string(from: range.start)
        let endTime = dateFormatter.string(from: range.end)
        
        return APIConstant.medicationEndpoint + "?" + APIConstant.startParameter + startTime + "&" + APIConstant.endParameter + endTime
    }
    
    private static var todayDateRange: (start: Date, end: Date) {
        var dateComponents = DateComponents()
        dateComponents.day = 1
        
        let calendar = Calendar.current
        
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: dateComponents, to: start)! // TODO: better handling of optional
        
        return (start, end)
    }
    
    func getMedications(completion: @escaping (_ medications: [Medication]?, _ error: Error?) -> Void) {
        
        Alamofire.request(URL(string: todaysMedicationsEndpoint)!).responseJSON { (response) in
            
            if response.result.isSuccess {
                if let value = response.result.value {
                    let json = JSON(value)
                    
                    var medications = [Medication]()
                    for (_, row) in json {
                        if let medication = Medication(json: row) {
                            medications.append(medication)                            
                        }
                    }
                    completion(medications, nil)
                    return
                }
            }
            
            completion(nil, response.result.error)
        }
    }
}
