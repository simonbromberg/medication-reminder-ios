//
//  MedicationViewController.swift
//  medication-reminder
//
//  Created by Simon Bromberg on 2017-06-07.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import UIKit
import AVFoundation

class MedicationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet private var tableView: UITableView!
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private var medications: [Medication]?
    
    private let cellName = MedicationCell.className
    
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getMedications()
        
        setupRefreshControl()
        
        registerNotifications()
    }
    
    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(getMedications), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func registerNotifications() {
        for notification in MedicationManager.NotificationType.allNotifications {
            NotificationCenter.default.addObserver(self, selector: #selector(receivedMedicationNotification), name: notification, object: nil)
        }
    }
    
    // MARK: - Get data
    
    @objc private func getMedications() {
        MedicationManager.sharedInstance.getMedications { (medications) in
            self.medications = medications
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - Alerts
    
    @objc private func receivedMedicationNotification(_ notification: Notification) {
        guard let medication = notification.object as? Medication,
            let type = MedicationManager.NotificationType(rawValue: notification.name.rawValue)
            else {
                return
        }
        
        switch type {
        case .soon:
            reloadRow(medication: medication)
            
        case .now:
            alertTakeMedication(medication)
            
        case .late:
            alertMedicationLate(medication)
            reloadRow(medication: medication)
            
        }
    }
    
    func reloadRow(medication: Medication) {
        if let index = index(medication: medication) {
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
    
    private func index(medication: Medication) -> Int? {
        return medications?.index(where: { (m) -> Bool in
            return m == medication
        })
    }
    
    // FIXME: edge case with concurrent medications
    
    private func alertTakeMedication(_ medication: Medication) {
        let message = medication.name + ": " + medication.dosage
        let alert = UIAlertController(title: "Take Medication", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ignore", style: .destructive, handler: nil))
        alert.addAction(UIAlertAction(title: "Taken", style: .default, handler: { (_) in
            
            MedicationManager.sharedInstance.completedMedication(medication)
            
            if let row = self.index(medication: medication) {
                self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            }
        }))
        
        present(alert, animated: true) {
            self.playNormalSound()
        }
    }

    private func alertMedicationLate(_ medication: Medication) {
        playAnnoyingSound()
    }
    
    // MARK: Sounds
    private let sound1: SystemSoundID = 1106
    private let sound2: SystemSoundID = 1254
    
    private func playNormalSound() {
        AudioServicesPlaySystemSound(sound1)
    }
    
    private func playAnnoyingSound() {
        AudioServicesPlaySystemSound(sound2)
    }
    
    // MARK: - Table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medications?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath) as! MedicationCell
        
        if let medication = medications?[indexPath.row] {
            let state = medication.state
            
            cell.setup(title: medication.name + ": " + medication.dosage, date: dateFormatter.string(from: medication.time), state: state)            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let medication = medications?[indexPath.row] {
            let state = medication.state
            if state.canBeCompleted {
                MedicationManager.sharedInstance.completedMedication(medication)
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
}
