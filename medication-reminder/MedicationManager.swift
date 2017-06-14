//
//  MedicationManager.swift
//  medication-reminder
//
//  Created by Simon Bromberg on 2017-06-12.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import Foundation

fileprivate let kRefreshDelay: TimeInterval = 10 * 60

let kFiveMinutes: TimeInterval = 5 * 60

extension NSNotification.Name {
    init(_ type: MedicationManager.NotificationType) {
        self = Notification.Name(type.rawValue)
    }
}

class MedicationManager {
    enum NotificationType: String {
        case soon, now, late
        
        var timeIntervalAddition: TimeInterval {
            switch self {
            case .soon:
                return -kFiveMinutes
            case .late:
                return kFiveMinutes
            default:
                return 0
            }
        }
        
        var notification: NSNotification.Name {
            return Notification.Name(self)
        }
        
        static var allNotifications: [NSNotification.Name] {
            return [NotificationType.soon.notification, NotificationType.now.notification, NotificationType.late.notification]
        }
    }
    
    static let sharedInstance = MedicationManager()
    
    private var medications: [Medication]?
    
    var medicationCount: Int {
        return medications?.count ?? 0
    }
    
    subscript(index: Int) -> Medication? {
        if medications != nil && medications!.count > index {
            return medications![index]
        }
        
        return nil
    }
    
    func getMedications(completion: @escaping (_ medications: [Medication]?) -> Void) {
        NetworkManager.sharedInstance.getMedications { (medications, error) in
            self.medications = medications?.sorted(by: { (a, b) -> Bool in
                a.time.compare(b.time) == .orderedAscending
            })
            
            completion(self.medications)

            self.startScheduler()
        }
    }
    
    private var refreshTimer: Timer?
    private var timers = [String : Timer]()
    private let kMaxTimers = 20
    
    deinit {
        invalidateTimers()
    }
    
    private func invalidateTimers() {
        for timer in timers.values {
            timer.invalidate()
        }
        timers.removeAll()
        refreshTimer?.invalidate()
    }
    
    private func startScheduler() {
        invalidateTimers()
        
        if medications == nil {
            return
        }
        
        var shouldRefreshLater = false
        
        for medication in medications! {
            // go through medications and add timers
            
            let state = medication.state
            if state == .completed || state == .missed {
                continue
            }
            
            if timers.count > kMaxTimers {
                // Limit how many timers are scheduled
                // don't need to schedule timers for non-imminent medications
                shouldRefreshLater = true
                break
            }
            
            
            let time = medication.time.timeIntervalSinceNow
            let type: NotificationType
            switch time {
            case _ where time < -10:
                type = .late
            case -10...10:
                type = .now            
            default:
                type = .soon
            }
            
            scheduleNotification(medication: medication, notificationType: type)
        }
        
        if shouldRefreshLater {
            let later = Date().addingTimeInterval(kRefreshDelay)
            
            refreshTimer = Timer(fire: later, interval: 0, repeats: false, block: { (timer) in
                self.startScheduler()
            })
        }
    }
    
    func completedMedication(_ medication: Medication) {
        timers[medication.id]?.invalidate()
        timers[medication.id] = nil
        
        medication.completed = true
    }
    
    private func scheduleNotification(medication: Medication, notificationType type: NotificationType) {
        let fireDate = medication.time.addingTimeInterval(type.timeIntervalAddition)
                
        let notificationBlock = {
            NotificationCenter.default.post(name: type.notification, object: medication)
            
            if type == .soon {
                self.scheduleNotification(medication: medication, notificationType: .now)
            }
            else if type == .now {
                self.scheduleNotification(medication: medication, notificationType: .late)
            }
        }
        
        if fireDate.compare(Date()) != .orderedDescending {
            notificationBlock()
            return
        }
        
        let timer = Timer.init(fire: fireDate, interval: 0, repeats: false, block: { (timer) in
            notificationBlock()
        })
        timer.tolerance = 5
        RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
        timers[medication.id] = timer
    }
}
