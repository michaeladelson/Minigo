//
//  BoardViewPoint.swift
//  Minigo
//
//  Created by Michael Adelson on 10/14/19.
//  Copyright © 2019 Michael L. Adelson. All rights reserved.
//

import UIKit

/*
 * A view that shows a stone on a BoardView
 */
class BoardViewPoint: UIView
{
    /*
     * The different colors a stone can have.
     */
    enum PointColor
    {
        case black
        case white
        case none
    }
    
    var color = PointColor.none { didSet { setNeedsDisplay() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    override func draw(_ rect: CGRect) {
        switch color {
        case .black:
            UIColor.black.setStroke()
            UIColor.black.setFill()
        case .white:
            UIColor.white.setStroke()
            UIColor.white.setFill()
        case .none:
            UIColor.clear.setStroke()
            UIColor.clear.setFill()
        }
        
        let path = UIBezierPath()
        
        path.addArc(withCenter: CGPoint(x: self.bounds.width/2, y: self.bounds.height/2),
                    radius: Constants.radiusRatio * CGFloat.minimum(self.bounds.width/2, self.bounds.height/2),
                    startAngle: 0.0,
                    endAngle: 2 * CGFloat.pi,
                    clockwise: true)
        
        path.stroke()
        path.fill()
    }
    
    private struct Constants {
        static let radiusRatio: CGFloat = 0.95
    }
    
    private func setUp() {
        contentMode = .redraw
        backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
    }
}
