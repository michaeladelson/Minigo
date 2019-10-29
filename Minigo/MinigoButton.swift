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
            if isHighlighted {
                self.alpha = 0.2
            } else {
                self.alpha = self.isEnabled ? 1.0 : 0.2
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
