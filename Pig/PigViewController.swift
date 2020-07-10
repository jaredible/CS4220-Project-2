import UIKit
import ObjectLibrary

final class PigViewController: UIViewController {
    
    /// We definitely need these so that we can reference our UI elements. 😐
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var diceImageView: UIImageView!
    @IBOutlet private weak var pointsRolledLabel: UILabel!
    @IBOutlet private weak var playerOnePointsLabel: UILabel!
    @IBOutlet private weak var playerTwoPointsLabel: UILabel!
    @IBOutlet private weak var resetButton: RoundButton!
    @IBOutlet private weak var rollButton: RoundButton!
    @IBOutlet private weak var holdButton: RoundButton!
    
    /// Defines the precious game model!
    private lazy var model = { PigModel(delegate: self) }()
    /// This is here so that we can create and remove it from the view.
    private var particleEmitter: CAEmitterLayer?
    /// Defines some UI animation transitions used for die rolling.
    private let transitions = [
        UIView.AnimationOptions.transitionFlipFromBottom,
        UIView.AnimationOptions.transitionFlipFromRight,
        UIView.AnimationOptions.transitionFlipFromTop,
        UIView.AnimationOptions.transitionFlipFromLeft
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Launch a new game upon loading the app. 🚀
        beginNewGame()
    }
    
    /// Called when the reset button is tapped.
    @IBAction func resetButtonTapped(_ sender: Any) {
        // Begin a new game!
        beginNewGame()
    }
    
    /// Called when the roll button is tapped.
    @IBAction func rollButtonTapped(_ sender: Any) {
        // We should probably let the game model know that a roll has occured. 😁
        model.roll()
    }
    
    /// Called when the hold button is tapped.
    @IBAction func holdButtonTapped(_ sender: Any) {
        // We should probably let the game model know that a hold has occured. 😮
        model.hold()
    }
    
    /// Implements what is needed when beginning a new game.
    func beginNewGame() {
        // Remove the particles if there are any.
        particleEmitter?.removeFromSuperlayer()
        
        // Set some default UI stuff.
        diceImageView.image = UIImage(named: "pig")
        pointsRolledLabel.text = "0"
        resetButton.isEnabled = false
        rollButton.isEnabled = true
        holdButton.isEnabled = false
        
        // Tell the model that it's game on!
        model.beginNewGame()
    }
    
    /// Helper function used for the UI buttons.
    func enableButtons(_ enabled: Bool) {
        resetButton.isEnabled = enabled
        rollButton.isEnabled = enabled
        holdButton.isEnabled = enabled
    }
    
    /// Creates randomly downward-rotating and fading pig-image particles.
    func createParticles() {
        // I ❤️ emitters.
        particleEmitter = CAEmitterLayer()
        
        guard let emitter = particleEmitter else { return }
        
        emitter.emitterPosition = CGPoint(x: view.frame.width / 2.0, y: -50)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.frame.width, height: 1)
        emitter.renderMode = .additive

        let cell = CAEmitterCell()
        cell.birthRate = 1
        cell.lifetime = 20.0
        cell.velocity = 100
        cell.velocityRange = 50
        cell.emissionLongitude = .pi
        cell.spinRange = 5
        cell.scale = 0.5
        cell.scaleRange = 0.25
        cell.color = UIColor(white: 1, alpha: 0.25).cgColor
        cell.alphaSpeed = -0.05
        cell.contents = UIImage(named: "icon")?.cgImage
        emitter.emitterCells = [cell]
        
        view.layer.addSublayer(emitter)
    }
    
}

extension PigViewController: PigModelDelegate {
    
    func show(_ roll: Roll, _ closure: @escaping (_ die: Die?) -> ()) {
        // 10x software engineering right here.
        let dice = roll.dieChanges
        
        enableButtons(false)
        
        func doRoll(_ index: Int) {
            let dieChange = dice[index]
            
            diceImageView.image = dieChange.die.face
            
            if index == dice.count - 1 {
                enableButtons(true)
                closure(dice.last?.die)
                return
            }
            
            let randomTransition = transitions[Int.random(in: 0..<4)]
            
            UIView.transition(with: diceImageView, duration: dieChange.duration, options: randomTransition, animations: nil, completion: { _ in
                doRoll(index + 1)
            })
        }
        
        doRoll(0)
    }
    
    func update(_ pointsRolled: Int) {
        // We should probably let the current player know their roll score.
        pointsRolledLabel.text = String(pointsRolled)
    }
    
    func updateScore(for player: Player) {
        // Set the given player's score.
        let totalPoints = String(player.totalPoints)
        switch player.id {
        case Player.Identifier.one:
            playerOnePointsLabel.text = totalPoints
        case Player.Identifier.two:
            playerTwoPointsLabel.text = totalPoints
        }
    }
    
    func willChange(player: Player) {
        // Disable the hold button because when a player changes, they don't have an option to tap it.
        holdButton.isEnabled = false
    }
    
    func updateGameLog(text: String) {
        // Update the title text.
        titleLabel.text = text
    }
    
    func notifyWinner(alertTitle: String, message: String, actionTitle: String) {
        // Show some particles because it looks cool.
        createParticles()
        // Show who won the game.
        presentSingleActionAlert(alerTitle: alertTitle, message: message, actionTitle: actionTitle, completion: beginNewGame)
    }
    
}
