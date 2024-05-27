import UIKit
import AVFoundation

var player: AVAudioPlayer!

class ViewController: UIViewController {

    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var image4: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func button(_ sender: UIButton) {
        playSound()

        guard let url = Bundle.main.url(forResource: "Dice Sound", withExtension: "m4a") else {
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player.play()
        } catch {
            print("Error loading audio file: \(error)")
        }

        let images = [#imageLiteral(resourceName: "Dice 1"), #imageLiteral(resourceName: "Dice 2"), #imageLiteral(resourceName: "Dice 3"), #imageLiteral(resourceName: "Dice 4"), #imageLiteral(resourceName: "Dice 5"), #imageLiteral(resourceName: "Dice 6")]

        image2.image = images.randomElement()
        image3.image = images.randomElement()
        image4.image = images.randomElement()
    }

    func playSound() {
        // این تابع همچنان باقی مانده است، زیرا خطای Optional در این تابع ایجاد نمی‌شود.
    }
}

