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

        guard let url = Bundle.main.url(forResource: "New Recording 2", withExtension: "m4a") else {
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player.play()
        } catch {
            print("Error loading audio file: \(error)")
        }

        let images = [#imageLiteral(resourceName: "Untitled-2"), #imageLiteral(resourceName: "Untitled-3"), #imageLiteral(resourceName: "Untitled-4"), #imageLiteral(resourceName: "Untitled-5"), #imageLiteral(resourceName: "Untitled-6"), #imageLiteral(resourceName: "Untitled-7")]

        image2.image = images.randomElement()
        image3.image = images.randomElement()
        image4.image = images.randomElement()
    }

    func playSound() {
        // این تابع همچنان باقی مانده است، زیرا خطای Optional در این تابع ایجاد نمی‌شود.
    }
}

