//
//  MinigoButton.swift
//  Minigo
//
//  Created by Michael Adelson on 10/19/19.
//  Copyright © 2019 Michael L. Adelson. All rights reserved.
//

import UIKit

class MinigoButton: UIButton {

    override var isHighlighted: Bool {
        didSet {
            if isEnabled {
                if isHighlighted {
                    self.alpha = 0.2
                } else {
                    self.alpha = 1.0
                }
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.alpha = 1.0
            } else {
                self.alpha = 2.0
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if titleLabel != nil {
            titleLabel!.font = titleLabel!.font.withSize(0.66 * frame.height)
        }
    }
    

}
