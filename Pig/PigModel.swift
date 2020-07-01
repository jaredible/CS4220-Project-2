import Foundation
import class ObjectLibrary.Player
import enum ObjectLibrary.Die

protocol PigModelDelegate: class {
    func update(die: Die)
    func update(_ pointsRolled: Int)
    func updateScore(for player: Player)
    func willChange(player: Player)
    func updateGameLog(text: String)
    func notifyWinner(alerTitle: String, message: String, actionTitle: String)
}

final class PigModel {
    
    private let players: [Player]
    private weak var delegate: PigModelDelegate?
    private var isPlayerTwosTurn: Bool = false { didSet { delegate?.willChange(player: currentPlayer) }}
    private var pointsRolled: Int = 0
    private var currentPlayer: Player { players[Int(truncating: isPlayerTwosTurn as NSNumber)] }
        
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
        let pointsRolled = randomDie.value
        self.pointsRolled += pointsRolled
        delegate?.update(die: randomDie)
        delegate?.update(self.pointsRolled)
        var rollText = "\(currentPlayer.name) rolled a \(pointsRolled)."
        if pointsRolled == 1 {
            rollText += "\n\(nextPlayer().name), you're up!"
            self.pointsRolled = 0
            delegate?.update(self.pointsRolled)
            isPlayerTwosTurn.toggle()
        }
        delegate?.updateGameLog(text: rollText)
    }
    
    func hold() {
        currentPlayer.updateScore(byAdding: pointsRolled)
        if currentPlayer.totalPoints >= 100 {
            delegate?.update(pointsRolled)
            delegate?.updateScore(for: currentPlayer)
            delegate?.notifyWinner(alerTitle: "Winner!", message: "\(currentPlayer.name), you won!", actionTitle: "New Game")
        } else {
            pointsRolled = 0
            delegate?.update(pointsRolled)
            delegate?.updateScore(for: currentPlayer)
            delegate?.updateGameLog(text: "\(currentPlayer.name) holds.\n\(nextPlayer().name), you're up!")
            isPlayerTwosTurn.toggle()
        }
    }
    
    private func nextPlayer() -> Player {
        return isPlayerTwosTurn ? players[0] : players[1]
    }
    
}
