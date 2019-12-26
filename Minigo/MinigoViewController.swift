//
//  MinigoViewController.swift
//  Minigo
//
//  Created by Michael Adelson on 9/7/19.
//  Copyright © 2019 Michael L. Adelson. All rights reserved.
//

import UIKit
import GameKit

/*
 * A user interface that allows a player to play a game of Go.
 */
class MinigoViewController: UIViewController, BoardViewDelegate, GKTurnBasedMatchmakerViewControllerDelegate, GKLocalPlayerListener
{
    // The current match displayed by the viewController.
    var currentMatch: GKTurnBasedMatch? {
        didSet {
            if let match = currentMatch {
                match.loadMatchData() { data, error in
                    DispatchQueue.main.async {
                        self.minigoMatchData = data
                        self.turnNumberToDisplay = self.minigoGame.turnCount
                        self.updateViewFromModel()
                    }
                }
            } else {
                minigoMatchData = nil
                turnNumberToDisplay = 0
                self.updateViewFromModel()
            }
        }
    }
    
    // The number of turns that have been taken in the current match.
    var numberOfTurns: Int {
        return minigoGame.turnCount
    }
    
    /*
     * The turn number of the current match displayed by the viewController.
     * Must be greater than or equal to 0 and less than or equal to numberOfTurns.
     */
    var turnNumberToDisplay = 0 {
        didSet {
            updateViewFromModel()
        }
    }
    
    // Sets the board to show the current match position.
    func setBoardToCurrentPosition() {
        turnNumberToDisplay = minigoGame.turnCount
    }
    
    
    /*
     * A struct that represents the details of a Minígo match.
     */
    private struct MinigoMatchState: Codable
    {
        let blackPlayerID: String?
        let whitePlayerID: String?
        let minigoMoveHistory: [MinigoGame.Point?]
    }
    
    private struct Constants {
        static let boardSize = 9
        static let buttonsCornerRadius: CGFloat = 6.0
        static let fontSizeToButtonHeightRatio: CGFloat = 0.66
        static let fontSizeToClockEmojiLabelHeightRatio: CGFloat = 0.9
    }
    
    @IBOutlet private weak var boardViewContainer: UIView! {
        didSet {
            boardView = BoardView(boardSize: Constants.boardSize, frame: boardViewContainer.bounds)
            boardView.delegate = self

            boardViewContainer.addSubview(boardView)
        }
    }
    
    @IBOutlet private weak var rewindButton: MinigoButton! {
        didSet {
            rewindButton.layer.cornerRadius = Constants.buttonsCornerRadius
            rewindButton.adjustsImageWhenHighlighted = false
            rewindButton.isEnabled = false
        }
    }
    
    @IBOutlet private weak var fastForwardButton: MinigoButton! {
        didSet {
            fastForwardButton.layer.cornerRadius = Constants.buttonsCornerRadius
            fastForwardButton.adjustsImageWhenHighlighted = false
            fastForwardButton.isEnabled = false
        }
    }
    
    @IBOutlet private weak var passButton: MinigoButton! {
        didSet {
            passButton.layer.cornerRadius = Constants.buttonsCornerRadius
            passButton.adjustsImageWhenHighlighted = false
            passButton.isEnabled = false
        }
    }
    
    
    @IBOutlet private weak var localPlayerNameLabel: UILabel!
    
    @IBOutlet private weak var localPlayerStatusLabel: UILabel!
    
    @IBOutlet private weak var localPlayerColorView: BoardViewPoint!
    
    @IBOutlet private weak var nonLocalPlayerNameLabel: UILabel!
    
    @IBOutlet private weak var nonLocalPlayerStatusLabel: UILabel!
    
    @IBOutlet private weak var nonLocalPlayerColorView: BoardViewPoint!
    
    @IBOutlet private weak var clockEmojiLabel: UILabel!
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var menuBarButtonItem: UIBarButtonItem!
    
    @IBOutlet private weak var resignBarButtonItem: UIBarButtonItem!
    
    // The current GKTurnBasedMatchmakerViewController displayed.
    private weak var currentMatchmakerViewController: GKTurnBasedMatchmakerViewController?
    
    // The model.
    private var minigoGame = MinigoGame(boardSize: Constants.boardSize)
    
    private var boardView: BoardView!
    
    // An observer that observes when the isAuthenticated property of the shared local player object changes.
    private var authenticationChangedObserver: NSObjectProtocol?
    
    // An observer that observes when the app is going to enter the foreground.
    private var willEnterForegroundObserver: NSObjectProtocol?
    
    // The gamePlayerID of the GKPlayer playing black.
    private var blackPlayerID: String?
    
    // The gamePlayerID of the GKPlayer playing white.
    private var whitePlayerID: String?
    
    // The match state of the current match.
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
            
            setPlayerIDs()
        }
    }
    
    // The match state of the current match encoded as a Data instance
    private var minigoMatchData: Data? {
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
    
    // The GKTurnBasedParticipant playing black.
    private var blackParticipant: GKTurnBasedParticipant? {
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
    
    // The GKTurnBasedParticipant playing white.
    private var whiteParticipant: GKTurnBasedParticipant? {
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
    
    // The GKPlayer playing black.
    private var blackPlayer: GKPlayer? {
        return blackParticipant?.player
    }
    
    // The GKPlayer playing white.
    private var whitePlayer: GKPlayer? {
        return whiteParticipant?.player
    }
    
    // The display name of the local player.
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
    
    // The display name of the non-local player.
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

    // The MinigoGame.Player that the local player is playing as in the current game.
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
    
    // The MinigoGame.Player that the non-local player is playing as in the current game.
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
    
    // A String that displays the status of the local player.
    private var localPlayerStatus: String? {
        if let localPlayerMatchOutcome = currentMatch?.localParticipant?.matchOutcome {
            switch localPlayerMatchOutcome {
            case .won:
                return "You Won"
            case .lost:
                return "You Lost"
            case .tied:
                return "You Tied"
            case .quit:
                return "You Quit"
            case .none:
                if GKLocalPlayer.local == currentMatch?.currentParticipant?.player  {
                    return "Your Turn"
                } else if minigoGame.passCount == 1 {
                    return "Passed Last Turn"
                } else {
                    return ""
                }
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    // A String that displays the status of the non-local player.
    private var nonLocalPlayerStatus: String? {
        if let nonLocalPlayerMatchOutcome = currentMatch?.nonLocalParticipants.first?.matchOutcome {
            switch nonLocalPlayerMatchOutcome {
            case .won:
                return "They Won"
            case .lost:
                return "They Lost"
            case .tied:
                return "They Tied"
            case .quit:
                return "They Quit"
            case .none:
                if GKLocalPlayer.local != currentMatch?.currentParticipant?.player  {
                    return "Their Turn"
                } else if minigoGame.passCount == 1 {
                    return "Passed Last Turn"
                } else {
                    return ""
                }
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    // A Boolean value indicating whether the current match position is being displayed.
    private var boardIsInCurrentPosition: Bool {
        return turnNumberToDisplay == minigoGame.turnCount
    }
    
    // A Boolean value indicating whether the local player can make a move.
    private var localPlayerCanMakeTurn: Bool {
        if let match = currentMatch {
            return GKLocalPlayer.local.isAuthenticated && GKLocalPlayer.local == match.currentParticipant?.player
        } else {
            return false
        }
    }
    
    // Presents a GKTurnBasedMatchmakerViewController
    @IBAction private func selectMatch(_ sender: UIBarButtonItem) {
        presentGKTurnBasedMatchmakerViewController()
    }
    
    // Shows the board position of the previous turn
    @IBAction private func rewind() {
        if turnNumberToDisplay > 0 {
            turnNumberToDisplay -= 1
        }
    }
    
    // Shows the board position of the next turn
    @IBAction private func fastForward() {
        if turnNumberToDisplay < minigoGame.turnCount {
            turnNumberToDisplay += 1
        }
    }
    
    // Passes the local player's turn
    @IBAction private func pass(_ sender: UIButton) {
        if boardIsInCurrentPosition {
            pass()
        } else {
            setBoardToCurrentPosition()
        }
    }
    
    // Resigns the local player from the current match.
    @IBAction private func resignLocalPlayer(_ sender: UIBarButtonItem) {
        guard let match = currentMatch else {
            return
        }
        
        if match.status != .ended && match.status != .unknown {
            let alert = UIAlertController(title: "Resign Match?",
                                          message: nil,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Resign",
                                          style: .default,
                                          handler: { (action: UIAlertAction) -> Void in self.resignLocalPlayer() }))
            alert.addAction(UIAlertAction(title: "Cancel",
                                          style: .default,
                                          handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // Sets the board to the current position
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
    
    // Presents a GKTurnBasedMatchmakerViewController
    private func presentGKTurnBasedMatchmakerViewController() {
        if GKLocalPlayer.local.isAuthenticated {
            let request = GKMatchRequest()
            request.minPlayers = 2
            request.maxPlayers = 2
            request.inviteMessage = "Would you like to play Minígo?"
            let matchmakerViewController = GKTurnBasedMatchmakerViewController(matchRequest: request)
            matchmakerViewController.turnBasedMatchmakerDelegate = self
            currentMatchmakerViewController = matchmakerViewController
            self.present(matchmakerViewController, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Multiplayer Unavailable",
                                          message: "Player is not signed in",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK",
                                          style: .default,
                                          handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // Resigns the local player from the current match.
    private func resignLocalPlayer() {
        guard let match = currentMatch else {
            return
        }
        
        if match.status != .ended && match.status != .unknown {
            if let localParticipant = match.localParticipant {
                if localParticipant == match.currentParticipant {
                    localParticipant.matchOutcome = .lost
                    
                    for participant in match.nonLocalParticipants {
                        participant.matchOutcome = .won
                    }
                    
                    match.endMatchInTurn(withMatch: match.matchData ?? Data()) { (err) -> Void in
                        self.updateViewFromModel()
                    }
                } else {
                    if localParticipant.matchOutcome == .none {
                        match.participantQuitOutOfTurn(with: .quit) { (err) -> Void in
                            self.updateViewFromModel()
                        }
                    }
                }
            }
        }
    }
    
    // Ends the current player's turn and updates the data stored on Game Center for the current match
    private func endTurn() {
        guard let match = currentMatch else {
            return
        }
        
        match.endTurn(
            withNextParticipants: match.nonCurrentParticipants,
            turnTimeout: GKTurnTimeoutDefault,
            match: minigoMatchData ?? Data()) { (err) -> Void in
                self.updateViewFromModel()
        }
    }
    
    // Passes the local player's turn.
    private func pass() {
        if localPlayerCanMakeTurn {
            let currentPlayer = minigoGame.currentPlayer
            let noncurrentPlayer = minigoGame.noncurrentPlayer
            minigoGame.pass()
            
            if minigoGame.passCount < 2 {
                endTurn()
            } else {
                // End the match
                if let match = currentMatch {
                    let currentPlayerScore = minigoGame.scoreOf(player: currentPlayer)
                    let nonCurrentPlayerScore = minigoGame.scoreOf(player: noncurrentPlayer)
                    if currentPlayerScore > nonCurrentPlayerScore {
                        for participant in match.participants {
                            if participant == match.currentParticipant {
                                participant.matchOutcome = .won
                            } else {
                                participant.matchOutcome = .lost
                            }
                        }
                    } else if currentPlayerScore < nonCurrentPlayerScore {
                        for participant in match.participants {
                            if participant == match.currentParticipant {
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
                    
                    match.endMatchInTurn(withMatch: minigoMatchData ?? Data()) { (err) -> Void in
                        self.updateViewFromModel()
                    }
                }
            }
        }
    }
    
    // Sets blackPlayerID and whitePlayerID
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
    
    // Updates the view to reflect the current state of the model.
    private func updateViewFromModel() {
        localPlayerNameLabel.text = localPlayerName ?? ""
        localPlayerStatusLabel.text = localPlayerStatus ?? ""
        localPlayerColorView.color = pointColor(for: localPlayerColor ?? .none)
        
        nonLocalPlayerNameLabel.text = nonLocalPlayerName ?? ""
        nonLocalPlayerStatusLabel.text = nonLocalPlayerStatus ?? ""
        nonLocalPlayerColorView.color = pointColor(for: nonLocalPlayerColor ?? .none)
        
        boardView.updateColorForAllPoints()
        
        if turnNumberToDisplay == 0 {
            rewindButton.isEnabled = false
        } else {
            rewindButton.isEnabled = true
        }
        
        if turnNumberToDisplay == minigoGame.turnCount {
            fastForwardButton.isEnabled = false
        } else {
            fastForwardButton.isEnabled = true
        }
        
        if turnNumberToDisplay == minigoGame.turnCount && localPlayerCanMakeTurn {
            passButton.isEnabled = true
        } else {
            passButton.isEnabled = false
        }
        
        if currentMatch != nil && currentMatch?.status != .ended {
            resignBarButtonItem.isEnabled = true
        } else {
            resignBarButtonItem.isEnabled = false
        }
    }
    
    // Gives the BoardViewPoint.PointColor that corresponds to a given MinigoGame.Player.
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
    
    // Sets GKLocalPlayer.local.authenticateHandler.
    private func setAuthenticationHandler() {
        GKLocalPlayer.local.authenticateHandler = { (vc, err) in
            if let authVC = vc {
                self.present(authVC, animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: ViewController Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .light

        menuBarButtonItem.isEnabled = GKLocalPlayer.local.isAuthenticated
        resignBarButtonItem.isEnabled = (currentMatch != nil && currentMatch?.status != .ended)
        
        if GKLocalPlayer.local.isAuthenticated {
            activityIndicator.stopAnimating()
        }
        
        setAuthenticationHandler()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(byHandlingGestureRecognizedBy:)))
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
                    self.menuBarButtonItem.isEnabled = true
                    self.activityIndicator.stopAnimating()
                } else {
                    GKLocalPlayer.local.unregisterAllListeners()
                    self.currentMatch = nil
                }
        }
        
        willEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: UIApplication.shared,
            queue: OperationQueue.main) { notification in
                // Set the current match to nil if the local player is not a player in the current match.
                if let match = self.currentMatch {
                    var players = [GKPlayer]()

                    for participant in match.participants {
                        if let player = participant.player {
                            players.append(player)
                        }
                    }

                    if !players.contains(GKLocalPlayer.local) {
                        self.currentMatch = nil
                    }
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
        
        if let observer = willEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
            willEnterForegroundObserver = nil
        }
    }
    
    override func viewDidLayoutSubviews() {
        //the following prints are for testing
//        print("localPlayerCanMakeTurn: \(localPlayerCanMakeTurn)") //just for testing
//        print("GKLocalPlayer.local.isAuthenticated: \(GKLocalPlayer.local.isAuthenticated)")  //just for testing
//
//        print("localPlayerDisplayName: \(GKLocalPlayer.local.displayName)")
        
        if let match = currentMatch {
            print(match.status.rawValue)
        }
        print(localPlayerStatus ?? "")
        print(nonLocalPlayerStatus ?? "")
        print("localPlayerNameLabel.adjustsFontSizeToFitWidth: \(localPlayerNameLabel.adjustsFontSizeToFitWidth)")
        
        print("blackPlayerID == nil: \(blackPlayerID == nil)")
        
        super.viewDidLayoutSubviews()
        boardView.frame = boardViewContainer.bounds
        
//        localPlayerStackView.layoutIfNeeded()
//        nonLocalPlayerStackView.layoutIfNeeded()
        
        localPlayerNameLabel.font = localPlayerNameLabel.font.withSize(Constants.fontSizeToButtonHeightRatio * localPlayerNameLabel.frame.height)
        localPlayerStatusLabel.font = localPlayerStatusLabel.font.withSize(Constants.fontSizeToButtonHeightRatio * localPlayerStatusLabel.frame.height)
        
        nonLocalPlayerNameLabel.font = nonLocalPlayerNameLabel.font.withSize(Constants.fontSizeToButtonHeightRatio * nonLocalPlayerNameLabel.frame.height)
        nonLocalPlayerStatusLabel.font = nonLocalPlayerStatusLabel.font.withSize(Constants.fontSizeToButtonHeightRatio * nonLocalPlayerStatusLabel.frame.height)
        
        clockEmojiLabel.font = clockEmojiLabel.font.withSize(Constants.fontSizeToClockEmojiLabelHeightRatio * clockEmojiLabel.frame.height)
        
    }
    
    // MARK: BoardViewDelegate methods
    
    func getColorForPointAt(_ boardView: BoardView, row: Int, column: Int) -> BoardViewPoint.PointColor {
        let stoneColor = minigoGame.boardHistory[turnNumberToDisplay][row][column]
        
        switch stoneColor {
        case .black:
            return .black
        case .white:
            return .white
        case .none:
            return .none
        }
    }
    
    func didSelectPointAt(_ boardView: BoardView, row: Int, column: Int) {
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
        for participant in match.participants {
            if participant.player == player {
                participant.matchOutcome = .lost
            } else {
                participant.matchOutcome = .won
            }
        }
        
        match.endMatchInTurn(withMatch: match.matchData ?? Data()) { (err) -> Void in
            self.updateViewFromModel()
        }
    }
    
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        if let matchmakerVC = currentMatchmakerViewController, didBecomeActive {
            currentMatchmakerViewController = nil
            matchmakerVC.dismiss(animated: true)
        }
        
        if didBecomeActive || currentMatch?.matchID == match.matchID {
            currentMatch = match
        }
        
        // End match if the other player quit
        if localPlayerCanMakeTurn {
            let nonLocalParticipantsWhichQuit = match.nonLocalParticipants.filter { $0.matchOutcome == .quit }
            if nonLocalParticipantsWhichQuit.count > 0 {
                for participant in nonLocalParticipantsWhichQuit {
                    participant.matchOutcome = .lost
                }
                match.currentParticipant?.matchOutcome = .won
                
                match.endMatchInTurn(withMatch: match.matchData ?? Data()) { (err) -> Void in
                    self.updateViewFromModel()
                }
            }
        }
    }
    
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        if currentMatch?.matchID == match.matchID {
            currentMatch = match
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


