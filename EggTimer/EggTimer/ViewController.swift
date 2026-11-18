//
//  ViewController.swift
//  EggTimer
//

import UIKit
import AVFoundation
import UserNotifications

final class ViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var circularProgressView: CircularProgressView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!

    // MARK: - Constants

    private enum Hardness: String {
        case soft = "Soft"
        case medium = "Medium"
        case hard = "Hard"

        /// Cooking time in seconds.
        var duration: Int {
            switch self {
            case .soft:   return 180   // 3 min
            case .medium: return 300   // 5 min
            case .hard:   return 480   // 8 min
            }
        }
    }

    private static let notificationID = "eggtimer.finished"

    // MARK: - Properties

    private var countdownTimer: Timer?
    private var audioPlayer: AVAudioPlayer?

    /// Total length of the current run (seconds). 0 when idle.
    private var totalTime: TimeInterval = 0
    /// Wall-clock moment the egg is done. Using a date (instead of decrementing
    /// a counter) keeps the timer accurate after the app was in the background.
    private var endDate: Date?
    private var lastShownSeconds: Int = -1

    private var isRunning: Bool { endDate != nil }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        timerLabel.font = .monospacedDigitSystemFont(ofSize: 38, weight: .regular)
        timerLabel.accessibilityTraits = .updatesFrequently
        statusLabel.accessibilityTraits = .updatesFrequently

        configureAudioSession()
        prepareAlarmPlayer()
        requestNotificationPermission()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        resetTimer()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        countdownTimer?.invalidate()
    }

    // MARK: - Actions

    @IBAction func hardnessSelected(_ sender: UIButton) {
        guard
            let title = sender.currentTitle,
            let hardness = Hardness(rawValue: title)
        else { return }

        startTimer(duration: hardness.duration, label: title)
    }

    @IBAction func resetTapped(_ sender: UIButton) {
        resetTimer()
    }

    // MARK: - Start

    private func startTimer(duration: Int, label: String) {

        stopAlarm()
        countdownTimer?.invalidate()

        totalTime = TimeInterval(duration)
        endDate = Date().addingTimeInterval(totalTime)
        lastShownSeconds = -1

        statusLabel.text = "Cooking \(label.lowercased()) egg..."
        resetButton.isEnabled = true
        resetButton.alpha = 1

        circularProgressView.setProgress(1, animated: false)
        updateDisplay()
        scheduleFinishNotification(after: totalTime, label: label)

        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // .common so the timer keeps firing while the user scrolls / interacts.
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }

    // MARK: - Tick

    private func tick() {
        guard let endDate = endDate else { return }

        let remaining = endDate.timeIntervalSinceNow

        if remaining <= 0 {
            finishTimer()
            return
        }

        updateDisplay()
    }

    // MARK: - Display

    private func updateDisplay() {
        guard let endDate = endDate, totalTime > 0 else { return }

        let remaining = max(endDate.timeIntervalSinceNow, 0)
        let secondsLeft = Int(remaining.rounded(.up))

        // Only touch the label once per second.
        if secondsLeft != lastShownSeconds {
            lastShownSeconds = secondsLeft
            showTime(secondsLeft)
        }

        circularProgressView.setProgress(
            CGFloat(remaining / totalTime),
            animated: false
        )
    }

    private func showTime(_ seconds: Int) {
        let text = String(format: "%02d:%02d", seconds / 60, seconds % 60)
        timerLabel.text = text
        timerLabel.accessibilityLabel = "\(seconds / 60) minutes \(seconds % 60) seconds remaining"
    }

    // MARK: - Finish

    private func finishTimer() {

        countdownTimer?.invalidate()
        countdownTimer = nil
        endDate = nil
        totalTime = 0

        showTime(0)
        circularProgressView.setProgress(0, animated: true, duration: 0.3)
        statusLabel.text = "Egg is ready!"

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        playAlarm()

        // Already in the app – the pending notification is no longer needed.
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
    }

    // MARK: - Reset

    private func resetTimer() {

        countdownTimer?.invalidate()
        countdownTimer = nil
        endDate = nil
        totalTime = 0
        lastShownSeconds = -1

        stopAlarm()
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationID])

        showTime(0)
        statusLabel.text = "Choose your egg"
        circularProgressView.setProgress(0, animated: false)

        resetButton.isEnabled = false
        resetButton.alpha = 0.4
    }

    // MARK: - Foreground handling

    @objc private func appDidBecomeActive() {
        // If the timer expired while the app was suspended, finish right away.
        if isRunning { tick() }
    }

    // MARK: - Alarm sound

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func prepareAlarmPlayer() {
        guard let url = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else {
            print("alarm_sound.mp3 not found in bundle")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Could not load alarm sound: \(error)")
        }
    }

    private func playAlarm() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }

    private func stopAlarm() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }

    // MARK: - Local notification (works when the app is in background)

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, error in
                if let error = error { print("Notification permission error: \(error)") }
            }
    }

    private func scheduleFinishNotification(after seconds: TimeInterval, label: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])

        let content = UNMutableNotificationContent()
        content.title = "Egg is ready! 🥚"
        content.body = "Your \(label.lowercased()) egg is done."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        let request = UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error { print("Could not schedule notification: \(error)") }
        }
    }
}
