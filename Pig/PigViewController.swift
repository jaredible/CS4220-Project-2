import UIKit
import ObjectLibrary

final class PigViewController: UIViewController {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var diceImageView: UIImageView!
    @IBOutlet private weak var pointsRolledLabel: UILabel!
    @IBOutlet private weak var playerOnePointsLabel: UILabel!
    @IBOutlet private weak var playerTwoPointsLabel: UILabel!
    @IBOutlet private weak var resetButton: RoundButton!
    @IBOutlet private weak var rollButton: RoundButton!
    @IBOutlet private weak var holdButton: RoundButton!
    
    private lazy var model = { PigModel(delegate: self) }()
    private var particleEmitter: CAEmitterLayer?
    private let transitions = [
        UIView.AnimationOptions.transitionFlipFromBottom,
        UIView.AnimationOptions.transitionFlipFromRight,
        UIView.AnimationOptions.transitionFlipFromTop,
        UIView.AnimationOptions.transitionFlipFromLeft
    ]
    
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
        particleEmitter?.removeFromSuperlayer()
        diceImageView.image = UIImage(named: "pig")
        pointsRolledLabel.text = "0"
        resetButton.isEnabled = false
        rollButton.isEnabled = true
        holdButton.isEnabled = false
        model.beginNewGame()
    }
    
    func enableButtons(_ enabled: Bool) {
        resetButton.isEnabled = enabled
        rollButton.isEnabled = enabled
        holdButton.isEnabled = enabled
    }
    
    func createParticles() {
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
    
    func show(_ roll: Roll, _ closure: @escaping () -> ()) {
        let dice = roll.dieChanges
        
        enableButtons(false)
        
        func doRoll(_ index: Int) {
            let dieChange = dice[index]
            let die = dieChange.die
            let duration = dieChange.duration
            
            diceImageView.image = die.face
            
            if index == dice.count - 1 {
                enableButtons(true)
                closure()
                return
            }
                        
            let randomTransition = transitions[Int.random(in: 0..<4)]
            
            UIView.transition(with: diceImageView, duration: duration, options: randomTransition, animations: nil, completion: { _ in
                doRoll(index + 1)
            })
        }
        
        doRoll(0)
    }
    
    func update(_ pointsRolled: Int) {
        pointsRolledLabel.text = String(pointsRolled)
    }
    
    func updateScore(for player: Player) {
        let totalPoints = String(player.totalPoints)
        switch player.id {
        case Player.Identifier.one:
            playerOnePointsLabel.text = totalPoints
        case Player.Identifier.two:
            playerTwoPointsLabel.text = totalPoints
        }
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
        createParticles()
        presentSingleActionAlert(alerTitle: alertTitle, message: message, actionTitle: actionTitle, completion: beginNewGame)
    }
    
}
