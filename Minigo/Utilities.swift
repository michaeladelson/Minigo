//
//  Utilities.swift
//  Go
//
//  Created by Michael Adelson on 8/8/19.
//  Copyright © 2019 Michael L. Adelson. All rights reserved.
//

import UIKit


extension CGPoint {
    func offset(by delta: CGPoint) -> CGPoint {
        return CGPoint(x: x + delta.x, y: y + delta.y)
    }
}

