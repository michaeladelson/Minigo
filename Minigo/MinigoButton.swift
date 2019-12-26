//
//  MinigoButton.swift
//  Minigo
//
//  Created by Michael Adelson on 10/19/19.
//  Copyright © 2019 Michael L. Adelson. All rights reserved.
//

import UIKit

/*
 * A button used as part of the Minígo user interface.
 * These buttons change their alpha value when highlighted or disabled and automatically adjust
 * their font size depending on the button height.
 */
class MinigoButton: UIButton {

    override var isHighlighted: Bool {
        didSet {
            if isEnabled {
                self.alpha = isHighlighted ? Constants.alpha : 1.0
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.alpha = isHighlighted ? Constants.alpha : 1.0
            } else {
                self.alpha = Constants.alpha
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if titleLabel != nil {
            titleLabel!.font = titleLabel!.font.withSize(Constants.fontSizeToHeightRatio * bounds.height)
        }
    }
    
    private struct Constants {
        static let alpha: CGFloat = 0.2
        static let fontSizeToHeightRatio: CGFloat = 0.66
    }
    
}
