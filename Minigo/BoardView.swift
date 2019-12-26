//
//  BoardView.swift
//  Minigo
//
//  Created by Michael Adelson on 8/7/19.
//  Copyright © 2019 Michael L. Adelson. All rights reserved.
//

import UIKit

/*
 * Methods that handle interactions with a boardView.
 */
protocol BoardViewDelegate: class
{
    // Tells the delegate a point on the board has been selected.
    func didSelectPointAt(_ boardView: BoardView, row: Int, column: Int)
    
    // Asks the delegate for the color of a point on the board.
    func getColorForPointAt(_ boardView: BoardView, row: Int, column: Int) -> BoardViewPoint.PointColor
}

/*
 * A view that presents a go gameboard.
 */
class BoardView: UIView {
    
    private(set) var boardSize = Constants.boardSize
    
    weak var delegate: BoardViewDelegate?
    
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
    
    override func draw(_ rect: CGRect) {
        let boardBoarderRect = CGRect(x: upperLeftCorner.x,
                             y: upperLeftCorner.y,
                             width: CGFloat(boardSize - 1) * lineSpacingWidthWise,
                             height: CGFloat(boardSize - 1) * lineSpacingHeightWise)
        
        let path = UIBezierPath(rect: boardBoarderRect)
        
        for i in 1..<boardSize - 1 {
            path.move(to: upperLeftCorner.offset(by: CGPoint(x: CGFloat(i) * lineSpacingWidthWise, y: 0)))
            path.addLine(to: upperLeftCorner.offset(by: CGPoint(x: CGFloat(i) * lineSpacingWidthWise, y: CGFloat(boardSize - 1) * lineSpacingHeightWise)))
        }
        
        for i in 1..<boardSize - 1 {
            path.move(to: upperLeftCorner.offset(by: CGPoint(x: 0, y: CGFloat(i) * lineSpacingHeightWise)))
            path.addLine(to: upperLeftCorner.offset(by: CGPoint(x: CGFloat(boardSize - 1) * lineSpacingWidthWise, y: CGFloat(i) * lineSpacingHeightWise)))
        }
        
        path.lineWidth = Constants.boardGridLineWidth
        
        UIColor.black.setStroke()
        path.stroke()
    }
    
    // Updates the color of every BoardViewPoint on the board.
    func updateColorForAllPoints() {
        for row in 0..<points.count {
            for column in 0..<points[row].count {
                if let color = delegate?.getColorForPointAt(self, row: row, column: column) {
                    points[row][column].color = color
                }
            }
        }
    }
    
    private struct Constants {
        static let boardSize = 9
        static let pointWidthToLineSpacingWidthWiseRatio: CGFloat = 0.99
        static let pointHeightToLineSpacingHeightWiseRatio: CGFloat = 0.99
        static let boardGridLineWidth: CGFloat = 3.0
        static let boardBackgroundColor = #colorLiteral(red: 1, green: 0.8323456645, blue: 0.4732058644, alpha: 1)
    }
    
    // The BoardViewPoints that appear on the board.
    private var points = [[BoardViewPoint]]()
    
    private var pointSize: CGSize {
        return CGSize(width: Constants.pointWidthToLineSpacingWidthWiseRatio * lineSpacingWidthWise,
                      height: Constants.pointHeightToLineSpacingHeightWiseRatio * lineSpacingHeightWise)
    }
    
    // Performs some set up work when called. The function is intended to be called when an instance of BoardView is instantiated.
    private func setUp() {
        backgroundColor = Constants.boardBackgroundColor
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
    
    // A function called when a boardViewPoint is tapped which tells the boardViewDelegate that a point has been selected.
    @objc private func selectPoint(byHandlingGestureRecognizedBy recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if let viewOfRecognizer = recognizer.view, let point = viewOfRecognizer as? BoardViewPoint, let (row, column) = getRowAndColumnOf(point: point) {
                delegate?.didSelectPointAt(self, row: row, column: column)
                updateColorForAllPoints()
            }
        default: break
        }
    }
    
    // Returns the row and column of a boardViewPoint on the board.
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
    
    // The horizontal spacing between grid lines on the board.
    private var lineSpacingWidthWise: CGFloat {
        return self.bounds.width / CGFloat(boardSize)
    }
    
    // The verticle spacing between grid lines on the board.
    private var lineSpacingHeightWise: CGFloat {
        return self.bounds.height / CGFloat(boardSize)
    }
    
    // The point where the upper left corner of the board grid is to be drawn.
    private var upperLeftCorner: CGPoint {
        return CGPoint(x: lineSpacingWidthWise/2, y: lineSpacingHeightWise/2)
    }
    
}

