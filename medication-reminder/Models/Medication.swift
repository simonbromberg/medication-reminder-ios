//
//  Medication.swift
//  medication-reminder
//
//  Created by Simon Bromberg on 2017-06-07.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import UIKit
import SwiftyJSON

struct MedicationKey {
    static let id = "_id"
    static let name = "name"
    static let dosage = "dosage"
    static let time = "time"
    static let completed = "completed"
}

class Medication {
    var id: String
    var name: String
    var dosage: String
    var time: Date
    var completed: Bool
    
    static func ==(lhs: Medication, rhs: Medication) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum State {
        case upcoming, soon, missed, completed
        
        var canBeCompleted: Bool {
            return self == .soon || self == .missed
        }
        
        var color: UIColor {
            switch self {
            case .completed:
                return UIColor(red: 0, green: 128/255, blue: 0, alpha: 1)
            case .soon:
                return .blue
            case .missed:
                return .red
            case .upcoming:
                return .black
            }
        }
    }
    
    static private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    init?(json: JSON) {
        guard let id = json[MedicationKey.id].string,
        let name = json[MedicationKey.name].string,
        let dosage = json[MedicationKey.dosage].string,
        let time = json[MedicationKey.time].string,
        let completed = json[MedicationKey.completed].bool
        else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.dosage = dosage
        
        guard let date = Medication.dateFormatter.date(from: time) else {
            return nil
        }
        self.time = date
        self.completed = completed                
    }
    
    // TESTING
    static var i = 0
    
    static func random() -> Medication? { //testing
        let medication = Medication(json: [
            MedicationKey.id: "key\(i)" as AnyObject,
            MedicationKey.name: "Medication \(i)" as AnyObject,
            MedicationKey.dosage: "99 mL" as AnyObject,
            MedicationKey.time: dateFormatter.string(from: Date().addingTimeInterval(-60 * 4 + TimeInterval(120 * i))) as AnyObject,
            MedicationKey.completed: false as AnyObject
            ])
        i += 1
        
        return medication
    }
    
    private let soonCutoff: TimeInterval = kFiveMinutes
    private let nowCutoff: TimeInterval = 10
    
    var state: State {
        if !completed {
            let timeInterval = time.timeIntervalSinceNow
            
            if abs(timeInterval) <= soonCutoff {
                return .soon                
            }
            
            if timeInterval < -soonCutoff {
                return .missed
            }
            
            return .upcoming
        }
            
        else {
            return .completed
        }
    }
}
