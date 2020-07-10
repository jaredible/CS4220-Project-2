import Foundation
import class ObjectLibrary.Player
import enum ObjectLibrary.Die
import typealias ObjectLibrary.DieChange
import struct ObjectLibrary.Roll

/// Defines behaviors (functions) that `PigModel` can invoke. This allows whoever conforms to this delegate to define its implementation.
protocol PigModelDelegate: class {
    /// Defines what happens when a die is rolled.
    func show(_ roll: Roll, _ closure: @escaping (_ die: Die?) -> ())
    /// Defines what happens when the total points rolled changes.
    func update(_ pointsRolled: Int)
    /// Defines what happens when a player's score changes.
    func updateScore(for player: Player)
    /// Defines what happens to notify when a player's turn is about to end.
    func willChange(player: Player)
    /// Defines what happens when the game's current state changes.
    func updateGameLog(text: String)
    /// Defined what happens to notify which player has won.
    func notifyWinner(alertTitle: String, message: String, actionTitle: String)
}

/// Defines the game's state and behaviour.
final class PigModel {
    
    /// String templates.
    static let welcomeMessage = "Welcome to Pig, %@!\nPress 'Roll' to begin."
    static let playerRolledMessage = "%@ rolled a %d."
    static let nextPlayerMessage = "\n%@, you're up!"
    static let playerHoldsMessage = "%@ holds.\n%@, you're up!"
    static let textHasWon = "%@ has won!"
    static let textNotificationTitle = "Winner"
    static let textNotificationMessage = "%@, it took\nyou %d rolls to win!"
    static let textNotificationActionTitle = "New Game"
        
    /// Amount of points a player has when their turn begins.
    private let defaultPointsRolled = 0
    /// Least amount of points needed for the game to be won.
    private let maxPoints = 100
    /// Amount of rolls a player has when the game begins.
    private let defaultRollCount = 0
    /// `Die` that ends a player's turn.
    private let turnEndingDie = Die.one
    /// Lower bound of rolls that can be performed.
    private let minRollCount = 5
    /// Upper bound of rolls that can be performed.
    private let maxRollCount = 10
    /// How long the roll takes.
    private let rollCountDuration = 0.15
    
    /// Reference to the `PigModelDelegate` so `PigModel` can exploit its behavior.
    private weak var delegate: PigModelDelegate?
    /// A list of all players playing the game.
    private let players: [Player]
    /// A list of players' total number of rolls.
    private var playerRollCounts: [Int]
    /// Remembers which player's turn it is. Upon changing this variable, `PigModelDelegate.willChange()` will be called with the current player.
    private var isPlayerTwosTurn: Bool = false { didSet { delegate?.willChange(player: currentPlayer) }}
    /// Remembers the current player, since only a single player can be rolling at a time.
    private var currentPlayer: Player { players[currentPlayerIndex()] }
    /// Remembers the player's total points rolled, since a player can roll many times. This value will always increase during a player's turn unless they roll `turnEndingDie`.
    private var pointsRolled: Int
    
    /// Initializes the game model.
    init(delegate: PigModelDelegate) {
        self.delegate = delegate
        players = Player.Identifier.allCases.map { Player(id: $0) }
        playerRollCounts = Array(repeating: defaultRollCount, count: players.count)
        pointsRolled = defaultPointsRolled
    }
    
    /// Begins a new game.
    func beginNewGame() {
        // Reset the points rolled.
        pointsRolled = defaultPointsRolled
        
        // Reset all players' score.
        players.forEach {
            $0.resetTotalPoints()
            delegate?.updateScore(for: $0)
        }
        
        // Resets all players' roll count.
        playerRollCounts = Array(repeating: defaultRollCount, count: players.count)
        
        // Set the current player to the first player.
        isPlayerTwosTurn = false
        
        // Show the game's beginning message.
        delegate?.updateGameLog(text: String(format: PigModel.welcomeMessage, currentPlayer.name))
    }
    
    /// Performs a die roll.
    func roll() {
        let count = Int.random(in: minRollCount...maxRollCount)
        let randomDice = getRandomDice(count)
        let totalDuration = rollCountDuration * Double(count)
        let roll = Roll(totalDuration: totalDuration, dieChanges: randomDice)
        
        // Show the die rolls.
        delegate?.show(roll, { die in
            guard let lastDie = die else { return }
            
            // Get the random die's value.
            let pointsRolled = lastDie.value
            
            // Since a player has rolled, increment their roll count.
            self.incrementPlayerRollCount()
            
            // Describes the game's current state when rolled. Its value will be used if the current player's turn hasn't ended.
            var message = String(format: PigModel.playerRolledMessage, self.currentPlayer.name, pointsRolled)
            // Check if the die rolled ends the turn.
            if self.dieIsTurnEnding(die: lastDie) {
                // Since the current player has rolled something that ends their turn, change the default string to reflect the next player's turn.
                message += String(format: PigModel.nextPlayerMessage, self.nextPlayer().name)
                // End the current player's turn.
                self.endTurn()
            } else {
                // Since the current player has rolled something that doesn't end their turn, update the total points rolled.
                self.pointsRolled += pointsRolled
            }
            
            // Notify the UI of the game's current state.
            self.update(message)
        })
    }
    
    /// Updates the current player's score, checks if they won, ends their turn, and invokes `delegate` behaviour.
    func hold() {
        let currentPlayer = self.currentPlayer, nextPlayer = self.nextPlayer(), rollCount = currentPlayerRollCount()
        
        // Update the current player's score.
        updatePlayerScore()
        // End the current player's turn.
        endTurn()
        
        // Define a variable to use to explain the game's current state when held. Its value will be used if the current player hasn't won.
        var message = String(format: PigModel.playerHoldsMessage, currentPlayer.name, nextPlayer.name)
        // Check if the current player's points have reached or surpassed the points required to win.
        if hasPlayerWon(player: currentPlayer) {
            // Since the current player has won, we need to change the default string to reflect a won game.
            message = String(format: PigModel.textHasWon, currentPlayer.name)
            // Invokes a delegate behavior to show which player has won, along with their score.
            delegate?.notifyWinner(alertTitle: PigModel.textNotificationTitle, message: String(format: PigModel.textNotificationMessage, currentPlayer.name, rollCount), actionTitle: PigModel.textNotificationActionTitle)
        }
        
        // Notify the UI of the game's current state.
        update(message)
    }
    
    /// Returns a `DieChange` array with random die and `rollCountDuration`.
    func getRandomDice(_ count: Int) -> [DieChange] {
        return (0..<count).map { _ in (Die.allCases.randomElement()!, rollCountDuration) }
    }
    
    /// Returns true if `die` is equal to `turnEndingDie`, false otherwise.
    func dieIsTurnEnding(die: Die) -> Bool {
        return die == turnEndingDie
    }
    
    /// Returns true if the current player has won, false otherwise.
    func hasPlayerWon(player: Player) -> Bool {
        player.totalPoints >= maxPoints
    }
    
    /// Updates the current player's score with the current points rolled, and invokes the delegate's `updateScore` behavior.
    private func updatePlayerScore() {
        currentPlayer.updateScore(byAdding: pointsRolled)
        delegate?.updateScore(for: currentPlayer)
    }
    
    /// Resets points rolled to zero and changes to the next player.
    private func endTurn() {
        pointsRolled = defaultPointsRolled
        isPlayerTwosTurn.toggle()
    }
    
    /// Abstracts away what should happen when `pointsRolled` changes. Invokes the delegate's `update` and `updateGameLog` behavior.
    private func update(_ message: String) {
        delegate?.update(pointsRolled)
        delegate?.updateGameLog(text: message)
    }
    
    /// Increments the current player's roll count.
    private func incrementPlayerRollCount() {
        playerRollCounts[currentPlayerIndex()] += 1
    }
    
    /// Returns the current player's roll count.
    private func currentPlayerRollCount() -> Int {
        return playerRollCounts[currentPlayerIndex()]
    }
    
    /// Returns the current player's index from the `players` array.
    private func currentPlayerIndex() -> Int {
        return Int(truncating: isPlayerTwosTurn as NSNumber)
    }
    
    /// Returns the next player based off the game's current state.
    private func nextPlayer() -> Player {
        return players[(Int(truncating: isPlayerTwosTurn as NSNumber) + 1) % players.count]
    }
    
}
