import UIKit
import ObjectLibrary

final class PigViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var diceImageView: UIImageView!
    @IBOutlet weak var pointsRolledLabel: UILabel!
    @IBOutlet weak var playerOnePointsLabel: UILabel!
    @IBOutlet weak var playerTwoPointsLabel: UILabel!
    @IBOutlet weak var resetButton: RoundButton!
    @IBOutlet weak var rollButton: RoundButton!
    @IBOutlet weak var holdButton: RoundButton!
    
    lazy var model = {
        return PigModel(delegate: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beginNewGame()
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        beginNewGame()
    }
    
    @IBAction func rollButtonTapped(_ sender: Any) {
        model.roll()
    }
    
    @IBAction func holdButtonTapped(_ sender: Any) {
        model.hold()
    }
    
    func beginNewGame() {
        model.beginNewGame()
        diceImageView.image = UIImage(named: "pig")
        pointsRolledLabel.text = "0"
        playerOnePointsLabel.text = "0"
        playerTwoPointsLabel.text = "0"
        rollButton.isEnabled = true
        holdButton.isEnabled = false
    }
    
}

extension PigViewController: PigModelDelegate {
    
    func update(die: Die) {
        diceImageView.image = die.face
    }
    
    func update(_ pointsRolled: Int) {
        pointsRolledLabel.text = String(pointsRolled)
        holdButton.isEnabled = true
    }
    
    func updateScore(for player: Player) {
        let totalPoints = String(player.totalPoints)
        switch player.id {
        case Player.Identifier.one:
            playerOnePointsLabel.text = totalPoints
        case Player.Identifier.two:
            playerTwoPointsLabel.text = totalPoints
        }
        holdButton.isEnabled = false
    }
    
    func willChange(player: Player) {
        holdButton.isEnabled = false
    }
    
    func updateGameLog(text: String) {
        titleLabel.text = text
    }
    
    func notifyWinner(alerTitle: String, message: String, actionTitle: String) {
        presentSingleActionAlert(alerTitle: alerTitle, message: message, actionTitle: actionTitle, completion: beginNewGame)
    }
    
}
