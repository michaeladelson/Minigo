//
//  BoardView.swift
//  Go
//
//  Created by Michael Adelson on 8/7/19.
//  Copyright © 2019 Michael L. Adelson. All rights reserved.
//

import UIKit

protocol BoardViewDelegate
{
    func didSelectPointAt(row: Int, column: Int)
    func getColorForPointAt(row: Int, column: Int) -> BoardViewPoint.PointColor
}

class BoardView: UIView {
    
    private(set) var boardSize = 9
    
    var delegate: BoardViewDelegate?
    
    init?(boardSize: Int, frame: CGRect) {
        if boardSize > 0 {
            self.boardSize = boardSize
            super.init(frame: frame)
            setUp()
        } else {
            return nil
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    private var points = [[BoardViewPoint]]()
    
    var pointSize: CGSize {
        return CGSize(width: 0.99 * lineSpacingWidthWise,
                      height: 0.99 * lineSpacingHeightWise)
    }
    
    func setUp() {
        backgroundColor = #colorLiteral(red: 1, green: 0.8323456645, blue: 0.4732058644, alpha: 1)
        contentMode = .redraw
        
        for _ in 0..<boardSize {
            var row = [BoardViewPoint]()
            
            for _ in 0..<boardSize {
                let point = BoardViewPoint(frame: CGRect.zero)
                let pointTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                       action: #selector(selectPoint(byHandlingGestureRecognizedBy:)))
                point.addGestureRecognizer(pointTapGestureRecognizer)
                self.addSubview(point)
                row.append(point)
            }
            points.append(row)
        }
    }
    
    @objc private func selectPoint(byHandlingGestureRecognizedBy recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if let viewOfRecognizer = recognizer.view {
                if let point = viewOfRecognizer as? BoardViewPoint {
                    if let (row, column) = getRowAndColumnOf(point: point) {
                        delegate?.didSelectPointAt(row: row, column: column)
                        updateColorForAllPoints()
                    }
                }
            }
        default: break
        }
    }
    
    
    private func getRowAndColumnOf(point: BoardViewPoint) -> (Int, Int)? {
        for row in 0..<points.count {
            for column in 0..<points[row].count {
                if points[row][column] == point {
                    return (row, column)
                }
            }
        }
        
        return nil
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for i in 0..<points.count {
            for j in 0..<points[i].count {
                
                points[i][j].frame.size = pointSize
                points[i][j].center = upperLeftCorner.offset(by: CGPoint(x: CGFloat(j) * lineSpacingWidthWise,
                                                                         y: CGFloat(i) * lineSpacingHeightWise))
            }
        }
    }
    
    
    func updateColorForAllPoints() {
        for row in 0..<points.count {
            for column in 0..<points[row].count {
                if let color = delegate?.getColorForPointAt(row: row, column: column) {
                    points[row][column].color = color
                }
            }
        }
    }
    

    private var lineSpacingWidthWise: CGFloat {
        return self.bounds.width / CGFloat(boardSize)
    }
    
    private var lineSpacingHeightWise: CGFloat {
        return self.bounds.height / CGFloat(boardSize)
    }
    
    private var upperLeftCorner: CGPoint {
        return CGPoint(x: lineSpacingWidthWise/2, y: lineSpacingHeightWise/2)
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        
        for i in 0..<boardSize {
            path.move(to: upperLeftCorner.offset(by: CGPoint(x: CGFloat(i) * lineSpacingWidthWise, y: 0)))
            path.addLine(to: upperLeftCorner.offset(by: CGPoint(x: CGFloat(i) * lineSpacingWidthWise, y: CGFloat(boardSize - 1) * lineSpacingHeightWise)))
        }
        
        for i in 0..<boardSize {
            path.move(to: upperLeftCorner.offset(by: CGPoint(x: 0, y: CGFloat(i) * lineSpacingHeightWise)))
            path.addLine(to: upperLeftCorner.offset(by: CGPoint(x: CGFloat(boardSize - 1) * lineSpacingWidthWise, y: CGFloat(i) * lineSpacingHeightWise)))
        }
        
        path.lineWidth = CGFloat(3.0)
        
        UIColor.black.setStroke()
        path.stroke()
    }

}

