import Foundation
import class ObjectLibrary.Player
import enum ObjectLibrary.Die

protocol PigModelDelegate: class {
    func update(_ die: Die)
    func update(_ pointsRolled: Int)
    func updateScore(for player: Player)
    func willChange(player: Player)
    func updateGameLog(text: String)
    func notifyWinner(alertTitle: String, message: String, actionTitle: String)
}

final class PigModel {
    
    private let players: [Player]
    private weak var delegate: PigModelDelegate?
    private var isPlayerTwosTurn: Bool = false { didSet { delegate?.willChange(player: currentPlayer) }}
    private var pointsRolled: Int = 0
    private var currentPlayer: Player { players[Int(truncating: isPlayerTwosTurn as NSNumber)] }
    private let maxPoints = 100
        
    init(delegate: PigModelDelegate) {
        self.delegate = delegate
        players = Player.Identifier.allCases.map { Player(id: $0) }
    }
        
    func beginNewGame() {
        pointsRolled = 0
        players.forEach {
            $0.resetTotalPoints()
            delegate?.updateScore(for: $0)
        }
        isPlayerTwosTurn = false
        delegate?.updateGameLog(text: "Welcome to Pig, \(currentPlayer.name)!\nPress 'Roll' to begin.")
    }
    
    func roll() {
        let randomDie = Die.allCases.randomElement()!
        delegate?.update(randomDie)
        let pointsRolled = randomDie.value
        var rollText = "\(currentPlayer.name) rolled a \(pointsRolled)."
        if randomDie == Die.one {
            rollText += "\n\(nextPlayer().name), you're up!"
            toggleTurn()
        } else {
            self.pointsRolled += pointsRolled
        }
        delegate?.update(self.pointsRolled)
        delegate?.updateGameLog(text: rollText)
    }
    
    func hold() {
        currentPlayer.updateScore(byAdding: pointsRolled)
        delegate?.updateScore(for: currentPlayer)
        if currentPlayer.totalPoints < maxPoints {
            delegate?.updateGameLog(text: "\(currentPlayer.name) holds.\n\(nextPlayer().name), you're up!")
            toggleTurn()
        } else {
            delegate?.updateGameLog(text: "\(currentPlayer.name) has won!")
            delegate?.notifyWinner(alertTitle: "Winner!", message: "\(currentPlayer.name),\nyou won with a score of \(currentPlayer.totalPoints).", actionTitle: "New Game")
        }
        delegate?.update(pointsRolled)
    }
    
    private func toggleTurn() {
        pointsRolled = 0
        isPlayerTwosTurn.toggle()
    }
    
    private func nextPlayer() -> Player {
        return players[(Int(truncating: isPlayerTwosTurn as NSNumber) + 1) % 2]
    }
    
}
