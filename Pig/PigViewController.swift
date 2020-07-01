import UIKit
import AVFoundation
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
    var timer: Timer?
    var rollCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        beginNewGame()
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        beginNewGame()
    }
    
    @IBAction func rollButtonTapped(_ sender: Any) {
        animateDie()
    }
    
    @IBAction func holdButtonTapped(_ sender: Any) {
        model.hold()
    }
    
    func beginNewGame() {
        model.beginNewGame()
        diceImageView.image = UIImage(named: "pig")
    }
    
    func animateDie() {
        rollCount = Int.random(in: 10..<20)
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(rollRandom), userInfo: nil, repeats: true)
    }
    
    @objc func rollRandom() {
        let randomDie = Die.allCases.randomElement()!
        update(randomDie)
        if rollCount == 0 {
            model.roll()
            timer?.invalidate()
            timer = nil
        }
        rollCount -= 1
    }
    
}

extension PigViewController: PigModelDelegate {
    
    func update(_ die: Die) {
        diceImageView.image = die.face
    }
    
    func update(_ pointsRolled: Int) {
        pointsRolledLabel.text = String(pointsRolled)
        if pointsRolled > 0 {
            holdButton.isEnabled = true
        }
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
        pointsRolledLabel.text = "0"
        rollButton.isEnabled = true
        holdButton.isEnabled = false
    }
    
    func updateGameLog(text: String) {
        titleLabel.text = text
    }
    
    func notifyWinner(alertTitle: String, message: String, actionTitle: String) {
        presentSingleActionAlert(alerTitle: alertTitle, message: message, actionTitle: actionTitle, completion: beginNewGame)
    }
    
}
