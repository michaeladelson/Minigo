//
//  MinigoViewController.swift
//  Minigo
//
//  Created by Michael Adelson on 9/7/19.
//  Copyright © 2019 Michael L. Adelson. All rights reserved.
//

import UIKit
import GameKit

class MinigoViewController: UIViewController, BoardViewDelegate, GKTurnBasedMatchmakerViewControllerDelegate, GKLocalPlayerListener
{
    
    @IBAction func selectMatch(_ sender: UIBarButtonItem) {
        presentGKTurnBasedMatchmakerViewController()
    }
    
    
    var minigoGame = MinigoGame(boardSize: 9)
    
    var boardView: BoardView!
    
    var authenticationChangedObserver: NSObjectProtocol?
    
    var currentMatch: GKTurnBasedMatch?
    
    var blackPlayerID: String?
    var whitePlayerID: String?
    
    var blackParticipant: GKTurnBasedParticipant? {
        if let id = blackPlayerID {
            if GKLocalPlayer.local.gamePlayerID == id {
                return currentMatch?.localParticipant
            } else {
                return currentMatch?.nonLocalParticipants.first
            }
        } else {
            return nil
        }
    }
    
    var whiteParticipant: GKTurnBasedParticipant? {
        if let id = whitePlayerID {
            if GKLocalPlayer.local.gamePlayerID == id {
                return currentMatch?.localParticipant
            } else {
                return currentMatch?.nonLocalParticipants.first
            }
        } else {
            return nil
        }
    }
    
    var blackPlayer: GKPlayer? {
        return blackParticipant?.player
    }
    
    var whitePlayer: GKPlayer? {
        return whiteParticipant?.player
    }
    
    private var localPlayerName: String? {
        if let match = currentMatch {
            if let name = match.localParticipant?.player?.displayName {
                return name
            } else {
                return "Anonoymous"
            }
        } else {
            return nil
        }
    }

    private var localPlayerColor: MinigoGame.Player? {
        if let localPlayerID = currentMatch?.localParticipant?.player?.gamePlayerID {
            if localPlayerID == blackPlayerID {
                return .black
            } else if localPlayerID == whitePlayerID {
                return .white
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private var localPlayerStatus: String? {
        if let match = currentMatch {
            if let localPlayerMatchOutcome = match.localParticipant?.matchOutcome {
                switch localPlayerMatchOutcome {
                case .won:
                    return "You Won"
                case .lost:
                    return "You Lost"
                case .tied:
                    return "You Tied"
                case .none:
                    if GKLocalPlayer.local == currentMatch?.currentParticipant?.player  {
                        return "Your Turn"
                    } else {
                        return ""
                    }
                default:
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private var nonLocalPlayerName: String? {
        if let match = currentMatch {
            if let name = match.nonLocalParticipants.first?.player?.displayName {
                return name
            } else {
                return "Anonoymous"
            }
        } else {
            return nil
        }
    }
    
    private var nonLocalPlayerColor: MinigoGame.Player? {
        if let localPlayerID = currentMatch?.localParticipant?.player?.gamePlayerID {
            if localPlayerID == blackPlayerID {
                return .white
            } else if localPlayerID == whitePlayerID {
                return .black
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    

    private var nonLocalPlayerStatus: String? {
        if let match = currentMatch {
            if let nonLocalPlayerMatchOutcome = match.nonLocalParticipants.first?.matchOutcome {
                switch nonLocalPlayerMatchOutcome {
                case .won:
                    return "They Won"
                case .lost:
                    return "They Lost"
                case .tied:
                    return "They Tied"
                case .none:
                    if GKLocalPlayer.local != currentMatch?.currentParticipant?.player  {
                        return "Their Turn"
                    } else {
                        return ""
                    }
                default:
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    
    var turnNumberToDisplay = 0 {
        didSet {
            updateViewFromModel()
        }
    }
    
    
    private var minigoMatchState: MinigoMatchState {
        get {
            return MinigoMatchState(blackPlayerID: blackPlayerID,
                                    whitePlayerID: whitePlayerID,
                                    minigoMoveHistory: minigoGame.moveHistory)
        }
        
        set {
            blackPlayerID = newValue.blackPlayerID
            whitePlayerID = newValue.whitePlayerID
            
            minigoGame.moveHistory = newValue.minigoMoveHistory
            
            //this might be a good place to set player IDs
            setPlayerIDs()
        }
    }
    
    var minigoMatchData: Data? {
        get {
            return try? JSONEncoder().encode(minigoMatchState)
        }
        
        set {
            if let data = newValue, let matchState = try? JSONDecoder().decode(MinigoMatchState.self, from: data) {
                minigoMatchState = matchState
            } else {
                minigoMatchState = MinigoMatchState(blackPlayerID: nil,
                                                    whitePlayerID: nil,
                                                    minigoMoveHistory: [MinigoGame.Point?]())
            }
        }
    }
    
    private weak var currentMatchmakerViewController: GKTurnBasedMatchmakerViewController?
    
    private var localPlayerCanMakeTurn: Bool {
        if let match = currentMatch {
            return GKLocalPlayer.local.isAuthenticated && GKLocalPlayer.local == match.currentParticipant?.player
        } else {
            return false
        }
    }
    
    @IBOutlet weak var boardViewContainer: UIView! {
        didSet {
            boardView = BoardView(boardSize: 9, frame: boardViewContainer.bounds)
            boardView.delegate = self

            boardViewContainer.addSubview(boardView)
        }
    }
    
    @IBOutlet weak var rewindButton: UIButton! {
        didSet {
            rewindButton.layer.cornerRadius = 6.0
        }
    }
    
    @IBOutlet weak var fastForwardButton: UIButton! {
        didSet {
            fastForwardButton.layer.cornerRadius = 6.0
            fastForwardButton.adjustsImageWhenHighlighted = false
        }
    }
    
    @IBOutlet weak var passButton: UIButton! {
        didSet {
            passButton.layer.cornerRadius = 8.0
        }
    }
    
    
    @IBOutlet weak var localPlayerNameLabel: UILabel!
    
    @IBOutlet weak var localPlayerStatusLabel: UILabel!
    
    @IBOutlet weak var localPlayerColorView: BoardViewPoint!
    
    @IBOutlet weak var nonLocalPlayerNameLabel: UILabel!
    
    @IBOutlet weak var nonLocalPlayerStatusLabel: UILabel!
    
    @IBOutlet weak var nonLocalPlayerColorView: BoardViewPoint!
    
    
    @IBOutlet weak var localPlayerColorViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var nonLocalPlayerColorViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var localPlayerStackView: UIStackView!
    
    @IBOutlet weak var nonLocalPlayerStackView: UIStackView!
    
    
    @IBAction func rewind() {
        if turnNumberToDisplay > 0 {
            turnNumberToDisplay -= 1
        }
    }
    
    @IBAction func fastForward() {
        if turnNumberToDisplay < minigoGame.turnCount {
            turnNumberToDisplay += 1
        }
    }
    
    @IBAction func pass(_ sender: UIButton) {
        if boardIsInCurrentPosition {
            pass()
        } else {
            setBoardToCurrentPosition()
        }
    }

    

    

    
    private func presentGKTurnBasedMatchmakerViewController() {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.inviteMessage = "Would you like to play Minígo?"
        let matchmakerViewController = GKTurnBasedMatchmakerViewController(matchRequest: request)
        matchmakerViewController.turnBasedMatchmakerDelegate = self
        currentMatchmakerViewController = matchmakerViewController
        self.present(matchmakerViewController, animated: true, completion: nil)
    }
    

    

    

    
    private func endTurn() {
        guard let match = currentMatch else {
            return
        }
        
        match.endTurn(
            withNextParticipants: match.nonCurrentParticipants,
            turnTimeout: GKTurnTimeoutDefault,
            match: minigoMatchData ?? Data(),
            completionHandler: nil)
    }
    

    
    @objc private func tap(byHandlingGestureRecognizedBy recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if !boardIsInCurrentPosition {
                setBoardToCurrentPosition()
            }
        default:
            break
        }
    }
    
//    @objc private func pass(byHandlingGestureRecognizedBy recognizer: UISwipeGestureRecognizer) {
//        switch recognizer.state {
//        case .ended:
//            if boardIsInCurrentPosition {
//                pass()
//            } else {
//                setBoardToCurrentPosition()
//            }
//
//        default: break
//        }
//    }
    
    private func pass() {
        if localPlayerCanMakeTurn {
            minigoGame.pass()
            setBoardToCurrentPosition()
            
            if minigoGame.passCount < 2 {
                endTurn()
            } else {
                if let match = currentMatch {
                    let currentPlayerScore = minigoGame.scoreOf(player: minigoGame.currentPlayer)
                    let nonCurrentPlayerScore = minigoGame.scoreOf(player: minigoGame.noncurrentPlayer)
                    if currentPlayerScore > nonCurrentPlayerScore {
                        for participant in match.participants {
                            if participant.player == match.currentParticipant {
                                participant.matchOutcome = .won
                            } else {
                                participant.matchOutcome = .lost
                            }
                        }
                    } else if currentPlayerScore < nonCurrentPlayerScore {
                        for participant in match.participants {
                            if participant.player == match.currentParticipant {
                                participant.matchOutcome = .lost
                            } else {
                                participant.matchOutcome = .won
                            }
                        }
                    } else {
                        for participant in match.participants {
                            participant.matchOutcome = .tied
                        }
                    }
                    
                    match.endMatchInTurn(withMatch: match.matchData ?? Data())
                }

            }
            
            
        }
    }
    
    
    private func setPlayerIDs() {
        if currentMatch?.status != GKTurnBasedMatch.Status.ended && currentMatch?.status != GKTurnBasedMatch.Status.unknown {
            if GKLocalPlayer.local == currentMatch?.currentParticipant?.player {
                if minigoGame.currentPlayer == .black {
                    blackPlayerID = GKLocalPlayer.local.gamePlayerID
                } else if minigoGame.currentPlayer == .white {
                    whitePlayerID = GKLocalPlayer.local.gamePlayerID
                }
            } else {
                if minigoGame.currentPlayer == .black {
                    whitePlayerID = GKLocalPlayer.local.gamePlayerID
                } else if minigoGame.currentPlayer == .white {
                    blackPlayerID = GKLocalPlayer.local.gamePlayerID
                }
            }
        }
    }
    
    private func updateViewFromModel() {
        localPlayerNameLabel.text = localPlayerName ?? ""
        localPlayerStatusLabel.text = localPlayerStatus ?? ""
        localPlayerColorView.color = pointColor(for: localPlayerColor ?? .none)
        //localPlayerColorView.frame.size = boardView.pointSize
        
        nonLocalPlayerNameLabel.text = nonLocalPlayerName ?? ""
        nonLocalPlayerStatusLabel.text = nonLocalPlayerStatus ?? ""
        nonLocalPlayerColorView.color = pointColor(for: nonLocalPlayerColor ?? .none)
        //nonLocalPlayerColorView.frame.size = boardView.pointSize
        
        boardView.updateColorForAllPoints()
        
        if turnNumberToDisplay == 0 {
            rewindButton.isEnabled = false
            rewindButton.alpha = 0.2
            print("rewindButton.alpha: \(rewindButton.alpha)")
        } else {
            rewindButton.isEnabled = true
            rewindButton.alpha = 1.0
        }
        
        if turnNumberToDisplay == minigoGame.turnCount {
            fastForwardButton.isEnabled = false
            fastForwardButton.alpha = 0.2
        } else {
            fastForwardButton.isEnabled = true
            fastForwardButton.alpha = 1.0
        }
        
    }
    
    private func pointColor(for player: MinigoGame.Player) -> BoardViewPoint.PointColor {
        switch player {
        case .black:
            return .black
        case .white:
            return .white
        case .none:
            return .none
        }
    }
    
    private func setBoardToCurrentPosition() {
        turnNumberToDisplay = minigoGame.turnCount
    }
    
    private var boardIsInCurrentPosition: Bool {
        return turnNumberToDisplay == minigoGame.turnCount
    }
    
    private struct MinigoMatchState: Codable
    {
        let blackPlayerID: String?
        let whitePlayerID: String?
        let minigoMoveHistory: [MinigoGame.Point?]
    }
    
    private func setAuthenticationHandler() {
        GKLocalPlayer.local.authenticateHandler = { (vc, err) in
            print("d")
            if let authVC = vc {
                print("a")
                print("vc != nil: \(vc != nil)")
                print("self.definesPresentationContext: \(self.definesPresentationContext)")
                self.present(authVC, animated: true, completion: {print("test test test")})
            } else if GKLocalPlayer.local.isAuthenticated {
                print("b")
            } else {
                print("c")
            }
        }
    }
    
    // MARK: Application Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setAuthenticationHandler()
        
        print("localPlayerColor == nil: \(localPlayerColor == nil)")
        print("currentMatch == nil: \(currentMatch == nil)")
        print("blackPlayerID == whitePlayerID: \(blackPlayerID == whitePlayerID)")
        print("nil == nil: \(nil == nil)")
        
        rewindButton.isEnabled = false
        rewindButton.alpha = 0.2
        fastForwardButton.isEnabled = false
        fastForwardButton.alpha = 0.2
        
//        let horizontalSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(pass(byHandlingGestureRecognizedBy:)))
//        horizontalSwipeGestureRecognizer.direction = [.left,.right]
//
//        let verticalSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(pass(byHandlingGestureRecognizedBy:)))
//        verticalSwipeGestureRecognizer.direction = [.up,.down]
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(byHandlingGestureRecognizedBy:)))

//        view.addGestureRecognizer(horizontalSwipeGestureRecognizer)
//        view.addGestureRecognizer(verticalSwipeGestureRecognizer)
        view.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        authenticationChangedObserver = NotificationCenter.default.addObserver(
            forName: .GKPlayerAuthenticationDidChangeNotificationName,
            object: nil,
            queue: OperationQueue.main) { notification in
                if GKLocalPlayer.local.isAuthenticated {
                    GKLocalPlayer.local.register(self)
                    self.setPlayerIDs()
//                    self.presentGKTurnBasedMatchmakerViewController()
                } else {
                    GKLocalPlayer.local.unregisterAllListeners()
                }
            }
        updateViewFromModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = authenticationChangedObserver {
            NotificationCenter.default.removeObserver(observer)
            authenticationChangedObserver = nil
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
//        localPlayerColorViewWidthConstraint.constant = boardView.pointSize.width
//        nonLocalPlayerColorViewWidthConstraint.constant = boardView.pointSize.width
    }
    
    override func viewDidLayoutSubviews() {
        //the following prints are for testing
        print("localPlayerCanMakeTurn: \(localPlayerCanMakeTurn)") //just for testing
        print("GKLocalPlayer.local.isAuthenticated: \(GKLocalPlayer.local.isAuthenticated)")  //just for testing
        
        print("localPlayerDisplayName: \(GKLocalPlayer.local.displayName)")
        
        if let match = currentMatch {
            print(match.status.rawValue)
        }
        print(localPlayerStatus ?? "")
        print(nonLocalPlayerStatus ?? "")
        print("localPlayerNameLabel.adjustsFontSizeToFitWidth: \(localPlayerNameLabel.adjustsFontSizeToFitWidth)")
        
        print("blackPlayerID == nil: \(blackPlayerID == nil)")
        
        super.viewDidLayoutSubviews()
        boardView.frame = boardViewContainer.bounds
        
        localPlayerColorViewWidthConstraint.constant = boardView.pointSize.width
        nonLocalPlayerColorViewWidthConstraint.constant = boardView.pointSize.width
        
        localPlayerStackView.layoutIfNeeded()
        nonLocalPlayerStackView.layoutIfNeeded()
        
        localPlayerNameLabel.font = localPlayerNameLabel.font.withSize(0.66 * localPlayerNameLabel.frame.height)
        localPlayerStatusLabel.font = localPlayerStatusLabel.font.withSize(0.66 * localPlayerStatusLabel.frame.height)
        
        nonLocalPlayerNameLabel.font = nonLocalPlayerNameLabel.font.withSize(0.66 * nonLocalPlayerNameLabel.frame.height)
        nonLocalPlayerStatusLabel.font = nonLocalPlayerStatusLabel.font.withSize(0.66 * nonLocalPlayerStatusLabel.frame.height)
        
    }
    
    // MARK: BoardViewDelegate methods
    
    func getColorForPointAt(row: Int, column: Int) -> BoardViewPoint.PointColor {
        let pieceColor = minigoGame.boardHistory[turnNumberToDisplay][row][column]
        
        switch pieceColor {
        case .black:
            return .black
        case .white:
            return .white
        case .none:
            return .none
        }
    }
    
    func didSelectPointAt(row: Int, column: Int) {
        if localPlayerCanMakeTurn && boardIsInCurrentPosition {
            let moveWasSuccessful = minigoGame.placeStoneAt(x: row, y: column)
            if moveWasSuccessful {
                endTurn()
            }
            setBoardToCurrentPosition()
        } else if !boardIsInCurrentPosition {
            setBoardToCurrentPosition()
        }
    }
    
    
    // MARK: GKTurnBasedMatchmakerViewControllerDelegate methods
    
    
    func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
        viewController.dismiss(animated: true)
    }
    
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
        print("TurnBasedMatchmakerViewController failed with error: \(error.localizedDescription).")
    }
    
    // MARK: GKLocalPlayerListener methods
    
    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        // need to write
        print("wantsToQuitMatch")
        for participant in match.participants {
            if participant.player == player {
                participant.matchOutcome = .lost
            } else {
                participant.matchOutcome = .won
            }
        }
        
        match.endMatchInTurn(withMatch: match.matchData ?? Data())
    }
    
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        print("receivedTurnEvent. didBecomeActive: \(didBecomeActive)")
        
        if let matchmakerVC = currentMatchmakerViewController, didBecomeActive {
            currentMatchmakerViewController = nil
            matchmakerVC.dismiss(animated: true)
        }
        
        if didBecomeActive {
            loadMatchData(match: match)
        }
//        loadMatchData(match: match)
        print("localPlayerCanMakeTurn: \(localPlayerCanMakeTurn)")
        //print("match.localParticipant?.matchOutcome: \(match.localParticipant?.matchOutcome.rawValue)")
        
        // End match if the other player quit
        if localPlayerCanMakeTurn {
            let nonLocalParticipantsWhichQuit = match.nonLocalParticipants.filter { $0.matchOutcome == .quit }
            if nonLocalParticipantsWhichQuit.count > 0 {
                for participant in nonLocalParticipantsWhichQuit {
                    participant.matchOutcome = .lost
                }
                match.currentParticipant?.matchOutcome = .won
                
                match.endMatchInTurn(withMatch: match.matchData ?? Data())
            }
            
        }
    }
    
    private func loadMatchData(match: GKTurnBasedMatch) {
        currentMatch = match
        match.loadMatchData() { data, error in
            DispatchQueue.main.async {
                self.minigoMatchData = data
                self.turnNumberToDisplay = self.minigoGame.turnCount
                self.updateViewFromModel()
            }
        }
    }
}


extension GKTurnBasedMatch
{
    var nonCurrentParticipants: [GKTurnBasedParticipant] {
        return participants.filter { $0 != currentParticipant }
    }
    
    var nonLocalParticipants: [GKTurnBasedParticipant] {
        return participants.filter { $0.player != GKLocalPlayer.local }
    }
    
    var localParticipant: GKTurnBasedParticipant? {
        let localParticipants = participants.filter { $0.player == GKLocalPlayer.local }
        return localParticipants.first
    }
}


