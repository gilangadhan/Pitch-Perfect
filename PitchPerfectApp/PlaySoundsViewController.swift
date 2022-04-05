//
//  PlaySoundsViewController.swift
//  PitchPerfectApp
//
//  Created by Gilang Ramadhan on 09/02/22.
//

import UIKit
import AVFoundation

class PlaySoundsViewController: UIViewController {

  @IBOutlet weak var rabbitButton: UIButton!
  @IBOutlet weak var snailButton: UIButton!
  @IBOutlet weak var chipmunkButton: UIButton!
  @IBOutlet weak var vaderButton: UIButton!
  @IBOutlet weak var echoButton: UIButton!
  @IBOutlet weak var reverbButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!

  var recordedAudioURL: URL!
  var audioFile: AVAudioFile!
  var audioEngine: AVAudioEngine!
  var audioPlayerNode: AVAudioPlayerNode!
  var stopTimer: Timer!

  enum ButtonType: Int {
    case slow = 0, fast, chipmunk, vader, echo, reverb
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupAudio()
  }
  
  @IBAction func playButton(_ sender: UIButton) {
      switch ButtonType(rawValue: sender.tag)! {
      case .slow:
          playSound(rate: 0.5)
      case .fast:
          playSound(rate: 1.5)
      case .chipmunk:
          playSound(pitch: 1000)
      case .vader:
          playSound(pitch: -1000)
      case .echo:
          playSound(echo: true)
      case .reverb:
          playSound(reverb: true)
      }

      configureUI(.playing)
  }

  @IBAction func stopButton(_ sender: Any) {
    stopAudio()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    configureUI(.notPlaying)
  }
}

extension PlaySoundsViewController: AVAudioPlayerDelegate {

  struct Alerts {
    static let DismissAlert = "Dismiss"
    static let RecordingDisabledTitle = "Recording Disabled"
    static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
    static let RecordingFailedTitle = "Recording Failed"
    static let RecordingFailedMessage = "Something went wrong with your recording."
    static let AudioRecorderError = "Audio Recorder Error"
    static let AudioSessionError = "Audio Session Error"
    static let AudioRecordingError = "Audio Recording Error"
    static let AudioFileError = "Audio File Error"
    static let AudioEngineError = "Audio Engine Error"
  }

  enum PlayingState { case playing, notPlaying }

  func setupAudio() {
    do {
      audioFile = try AVAudioFile(forReading: recordedAudioURL as URL)
    } catch {
      showAlert(Alerts.AudioFileError, message: String(describing: error))
    }
  }

  func playSound(
    rate: Float? = nil,
    pitch: Float? = nil,
    echo: Bool = false,
    reverb: Bool = false
  ) {

    audioEngine = AVAudioEngine()
    audioPlayerNode = AVAudioPlayerNode()
    audioEngine.attach(audioPlayerNode)

    let changeRatePitchNode = AVAudioUnitTimePitch()
    if let pitch = pitch {
      changeRatePitchNode.pitch = pitch
    }
    if let rate = rate {
      changeRatePitchNode.rate = rate
    }
    audioEngine.attach(changeRatePitchNode)

    let echoNode = AVAudioUnitDistortion()
    echoNode.loadFactoryPreset(.multiEcho1)
    audioEngine.attach(echoNode)

    let reverbNode = AVAudioUnitReverb()
    reverbNode.loadFactoryPreset(.cathedral)
    reverbNode.wetDryMix = 50
    audioEngine.attach(reverbNode)

    if echo == true && reverb == true {
      connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
    } else if echo == true {
      connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
    } else if reverb == true {
      connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
    } else {
      connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
    }

    audioPlayerNode.stop()
    audioPlayerNode.scheduleFile(audioFile, at: nil) {

      var delayInSeconds: Double = 0

      if let lastRenderTime = self.audioPlayerNode.lastRenderTime,
        let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
        let length = Double(self.audioFile.length - playerTime.sampleTime)
        let sampleRate = Double(self.audioFile.processingFormat.sampleRate)

        if let rate = rate {
          delayInSeconds =  length / sampleRate / Double(rate)
        } else {
          delayInSeconds = length / sampleRate
        }
      }

      self.stopTimer = Timer(
        timeInterval: delayInSeconds,
        target: self,
        selector: #selector(PlaySoundsViewController.stopAudio),
        userInfo: nil,
        repeats: false
      )
      RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
    }

    do {
      try audioEngine.start()
    } catch {
      showAlert(Alerts.AudioEngineError, message: String(describing: error))
      return
    }

    audioPlayerNode.play()
  }

  @objc func stopAudio() {

    if let audioPlayerNode = audioPlayerNode {
      audioPlayerNode.stop()
    }

    if let stopTimer = stopTimer {
      stopTimer.invalidate()
    }

    configureUI(.notPlaying)

    if let audioEngine = audioEngine {
      audioEngine.stop()
      audioEngine.reset()
    }
  }

  func connectAudioNodes(_ nodes: AVAudioNode...) {
    for value in 0..<nodes.count-1 {
      audioEngine.connect(nodes[value], to: nodes[value+1], format: audioFile.processingFormat)
    }
  }

  func configureUI(_ playState: PlayingState) {
    switch playState {
    case .playing:
      setPlayButtonsEnabled(false)
      stopButton.isEnabled = true
    case .notPlaying:
      setPlayButtonsEnabled(true)
      stopButton.isEnabled = false
    }
  }

  func setPlayButtonsEnabled(_ enabled: Bool) {
    snailButton.isEnabled = enabled
    chipmunkButton.isEnabled = enabled
    rabbitButton.isEnabled = enabled
    vaderButton.isEnabled = enabled
    echoButton.isEnabled = enabled
    reverbButton.isEnabled = enabled
  }

  func showAlert(_ title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
}
