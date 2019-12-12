//
//  Utilities.swift
//  Go
//
//  Created by Michael Adelson on 8/8/19.
//  Copyright © 2019 Michael L. Adelson. All rights reserved.
//

import UIKit


extension CGPoint {
    
    // Adds delta to this value.
    func offset(by delta: CGPoint) -> CGPoint {
        return CGPoint(x: x + delta.x, y: y + delta.y)
    }
}

extension UIViewController {
    var contents: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}
