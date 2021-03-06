//
//  MinigoGame.swift
//  Minigo
//
//  Created by Michael Adelson on 9/6/19.
//  Copyright © 2019 Michael L. Adelson. All rights reserved.
//

import Foundation

/*
 * A structure that represents a game of go.
 */
struct MinigoGame
{
    // The different values that a point on the game board can take.
    enum Player: Equatable
    {
        case black
        case white
        case none
    }
    
    // Represents a location on the game board.
    struct Point: Equatable, Codable, CustomStringConvertible
    {
        let x: Int
        let y: Int
        
        var description: String {
            return "(\(x), \(y))"
        }
    }
    
    private(set) var currentPlayer = Player.black
    
    private(set) var board = [[Player]]()
    
    private(set) var passCount = 0
    
    private(set) var boardHistory = [[[Player]]]()
    
    var blackScore: Double {
        return scoreOf(player: .black)
    }
    
    var whiteScore: Double {
        return scoreOf(player: .white)
    }
    
    var komi: Double {
        return Constants.komi
    }
    
    var noncurrentPlayer: Player {
        switch currentPlayer {
        case .black:
            return .white
        case .white:
            return .black
        case .none:
            return .none
        }
    }
    
    var boardSize: Int {
        return board.count
    }
    
    private var _moveHistory = [Point?]()
    
    // The sequence of moves in the game. A value of nil represents a passed turn.
    var moveHistory: [Point?] {
        get {
            return _moveHistory
        }
        
        set {
            currentPlayer = Player.black
            passCount = 0
            resetBoard()
            _moveHistory = [Point?]()
            boardHistory = [[[Player]]]()
            boardHistory.append(board)
            
            for point in newValue {
                _ = placeStoneAt(point: point)
            }
        }
    }
    
    var turnCount: Int {
        return _moveHistory.count
    }
    
    init(boardSize: Int) {
        for _ in 0..<boardSize {
            var row = [Player]()
            
            for _ in 0..<boardSize {
                row.append(.none)
            }
            board.append(row)
        }
        boardHistory.append(board)
    }
    
    // Returns the score for player.
    func scoreOf(player: Player) -> Double {
        var score = 0.0
        
        if player != .none {
            let otherPlayer = (player == Player.black ? Player.white : Player.black)
            
            let colorPoints = pointsWithColor(player)
            let emptyPointsThatReachColor = pointsThatReach(withColor: .none, toColor: player)
            let emptyPointsThatReachOtherColor = pointsThatReach(withColor: .none, toColor: otherPlayer)
            
            let pointsThatContributeToScore = colorPoints + emptyPointsThatReachColor.filter( { !emptyPointsThatReachOtherColor.contains($0) } )
            
            score = Double(pointsThatContributeToScore.count)
                
            if player == Player.white {
                score += Constants.komi
            }
        }
        
        return score
    }
    
    /*
     * The currentPlayer will place a stone on the xth row and yth column. It must be that 0 <= x < boardSize and 0 <= y < boardSize.
     * Returns true if the move was a legal move and false otherwise.
     */
    mutating func placeStoneAt(x: Int, y:Int) -> Bool {
        let point = Point(x: x, y: y)
        return placeStoneAt(point: point)
    }
    
    // Passes turn for the currentPlayer.
    mutating func pass() {
        _ = placeStoneAt(point: nil)
    }
    
    
    private struct Constants {
        static let komi = 5.5
    }
    
    private var blackPointsWithoutLiberties: [Point] {
        return pointsWithoutLiberties(withColor: .black)
    }
    
    private var whitePointsWithoutLiberties: [Point] {
        return pointsWithoutLiberties(withColor: .white)
    }
    
    private var blackPoints: [Point] {
        return pointsWithColor(.black)
    }
    
    private var whitePoints: [Point] {
        return pointsWithColor(.white)
    }
    
    
    // Returns all the Points with color.
    private func pointsWithColor(_ color: Player) -> [Point] {
        var colorPoints = [Point]()
        
        for i in 0..<boardSize {
            for j in 0..<boardSize {
                if board[i][j] == color {
                    let point = Point(x: i, y: j)
                    colorPoints.append(point)
                }
            }
        }
        
        return colorPoints
    }
    
    // Removes all of the stones from the board.
    private mutating func resetBoard() {
        for row in 0..<boardSize {
            for column in 0..<boardSize {
                board[row][column] = .none
            }
        }
    }
    
    
    /*
     * If point is not nil, then the current player places a stone at point on the board.
     * If point is nil, then the current player passes their turn.
     * Returns true if the move was a legal move and false otherwise.
     */
    private mutating func placeStoneAt(point: Point?) -> Bool {
        var moveWasSuccessful = false
        if let point = point {
            let x = point.x
            let y = point.y
            
            if (0 <= x && x < boardSize) && (0 <= y && y < boardSize) {
                if board[x][y] == .none {
                    board[x][y] = currentPlayer
                    
                    let noncurrentPlayerPointsWithoutLiberties = pointsWithoutLiberties(withColor: noncurrentPlayer)
                    
                    for pointWithoutLiberty in noncurrentPlayerPointsWithoutLiberties {
                        board[pointWithoutLiberty.x][pointWithoutLiberty.y] = .none
                    }
                    
                    let currentPlayerPointsWithoutLiberties = pointsWithoutLiberties(withColor: currentPlayer)
                    
                    var noncurrentPlayerTurnHistory = [[[Player]]]()
                    
                    for index in boardHistory.indices {
                        if (index % 2) == (noncurrentPlayer == Player.black ? 0 : 1) {
                            noncurrentPlayerTurnHistory.append(boardHistory[index])
                        }
                    }
                    
                    if currentPlayerPointsWithoutLiberties.isEmpty && !noncurrentPlayerTurnHistory.contains(board) {
                        boardHistory.append(board)
                        _moveHistory.append(point)
                        currentPlayer = noncurrentPlayer
                        passCount = 0
                        moveWasSuccessful = true
                    } else {
                        board = boardHistory.last!
                    }
                }
            }
        } else {
            boardHistory.append(board)
            _moveHistory.append(nil)
            currentPlayer = noncurrentPlayer
            passCount += 1
            moveWasSuccessful = true
        }
        return moveWasSuccessful
    }
    
    private func pointsWithoutLiberties(withColor color: Player) -> [Point] {
        return pointsThatDoNotReach(withColor: color, toColor: .none)
    }
    
    /*
     * Returns an array containing Points such that for each point board[point.x, point.y] == color and
     * point does not reach another Point p with board[p.x, p.y] == reachedColor.
     */
    private func pointsThatDoNotReach(withColor color: Player, toColor reachedColor: Player) -> [Point] {
        var pointsThatDoNoReach = [Point]()
        var pointsReaching = [Point]()
        
        for i in 0..<boardSize {
            for j in 0..<boardSize {
                let point = Point(x: i, y: j)

                if board[i][j] == color {
                    pointsThatDoNoReach.append(point)
                } else if board[i][j] == reachedColor {
                    pointsReaching.append(point)
                }
            }
        }
        
        while !pointsReaching.isEmpty {
            var newPointsReaching = [Point]()
            
            for point in pointsReaching {
                let i = point.x
                let j = point.y
                
                if i-1 >= 0 {
                    let newPoint = Point(x: i-1, y: j)
                    if let index = pointsThatDoNoReach.firstIndex(of: newPoint) {
                        pointsThatDoNoReach.remove(at: index)
                        newPointsReaching.append(newPoint)
                    }
                }
                
                if i+1 < boardSize {
                    let newPoint = Point(x: i+1, y: j)
                    if let index = pointsThatDoNoReach.firstIndex(of: newPoint) {
                        pointsThatDoNoReach.remove(at: index)
                        newPointsReaching.append(newPoint)
                    }
                }
                
                if j-1 >= 0 {
                    let newPoint = Point(x: i, y: j-1)
                    if let index = pointsThatDoNoReach.firstIndex(of: newPoint) {
                        pointsThatDoNoReach.remove(at: index)
                        newPointsReaching.append(newPoint)
                    }
                }
                
                if j+1 < boardSize {
                    let newPoint = Point(x: i, y: j+1)
                    if let index = pointsThatDoNoReach.firstIndex(of: newPoint) {
                        pointsThatDoNoReach.remove(at: index)
                        newPointsReaching.append(newPoint)
                    }
                }
            }
            
            pointsReaching = newPointsReaching
        }
        
        return pointsThatDoNoReach
    }
    
    /*
     * Returns an array containing Points such that for each point board[point.x, point.y] == color and
     * point reaches another Point p with board[p.x, p.y] == reachedColor.
     */
    private func pointsThatReach(withColor color: Player, toColor reachedColor: Player) -> [Point] {
        var pointsThatReach = [Point]()
        var pointsThatDoNoReach = [Point]()
        var pointsReaching = [Point]()
        
        for i in 0..<boardSize {
            for j in 0..<boardSize {
                let point = Point(x: i, y: j)

                if board[i][j] == color {
                    pointsThatDoNoReach.append(point)
                } else if board[i][j] == reachedColor {
                    pointsReaching.append(point)
                }
            }
        }
        
        while !pointsReaching.isEmpty {
            var newPointsReaching = [Point]()
            
            for point in pointsReaching {
                let i = point.x
                let j = point.y
                
                if i-1 >= 0 {
                    let newPoint = Point(x: i-1, y: j)
                    if let index = pointsThatDoNoReach.firstIndex(of: newPoint) {
                        pointsThatDoNoReach.remove(at: index)
                        newPointsReaching.append(newPoint)
                    }
                }
                
                if i+1 < boardSize {
                    let newPoint = Point(x: i+1, y: j)
                    if let index = pointsThatDoNoReach.firstIndex(of: newPoint) {
                        pointsThatDoNoReach.remove(at: index)
                        newPointsReaching.append(newPoint)
                    }
                }
                
                if j-1 >= 0 {
                    let newPoint = Point(x: i, y: j-1)
                    if let index = pointsThatDoNoReach.firstIndex(of: newPoint) {
                        pointsThatDoNoReach.remove(at: index)
                        newPointsReaching.append(newPoint)
                    }
                }
                
                if j+1 < boardSize {
                    let newPoint = Point(x: i, y: j+1)
                    if let index = pointsThatDoNoReach.firstIndex(of: newPoint) {
                        pointsThatDoNoReach.remove(at: index)
                        newPointsReaching.append(newPoint)
                    }
                }
            }
            
            pointsReaching = newPointsReaching
            pointsThatReach += newPointsReaching
        }
        
        return pointsThatReach
    }
    
}


