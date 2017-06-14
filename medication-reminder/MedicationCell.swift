//
//  MedicationCell.swift
//  medication-reminder
//
//  Created by Simon Bromberg on 2017-06-12.
//  Copyright © 2017 Vikas Gandhi. All rights reserved.
//

import UIKit

class MedicationCell: UITableViewCell {
    
    @IBOutlet private var mainLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var completedLabel: UILabel!
    // made to look like button, avoids need for delegation / cell knowing what medication it is by allowing didSelectRowAtIndexPath to take care of everything
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        completedLabel.alpha = 0
        mainLabel.text = nil
        dateLabel.text = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        completedLabel.alpha = 0
    }
    
    func setup(title: String, date: String, state: Medication.State) {
        let color = state.color
        
        mainLabel.text = title
        mainLabel.textColor = color
        
        dateLabel.text = date
        dateLabel.textColor = color
        
        isCompleted = state == .completed
        isMarkCompletedHidden = !state.canBeCompleted
    }
    
    var isCompleted: Bool = false {
        didSet {
            if isCompleted {
                isMarkCompletedHidden = true
            }
            
            accessoryType = isCompleted ? .checkmark : .none
        }
    }
    
    var isMarkCompletedHidden: Bool = true {
        didSet {
            let alpha: CGFloat = isMarkCompletedHidden ? 0 : 1    
            
            UIView.animate(withDuration: 0.2) { 
                self.completedLabel?.alpha = alpha
            }
        }
    }
}
