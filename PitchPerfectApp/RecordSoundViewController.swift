//
//  ViewController.swift
//  PitchPerfectApp
//
//  Created by Gilang Ramadhan on 28/12/21.
//

import UIKit
import AVFoundation

class RecordSoundViewController: UIViewController {

  var audioRecorder: AVAudioRecorder!

  @IBOutlet weak var recordingLabel: UILabel!
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var stopRecordingButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    recordingState(true)
  }

  @IBAction func recordAudio(_ sender: Any) {
    setupRecorder()
  }

  @IBAction func stopRecording(_ sender: Any) {
    audioRecorder.stop()
    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setActive(false)

    recordingState(true)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "stopRecording" {
      let playSoundsVC = segue.destination as? PlaySoundsViewController
      let recordedAudioURL = sender as? URL
      playSoundsVC?.recordedAudioURL = recordedAudioURL
    }
  }

  func setupRecorder() {
    let dirPath = NSSearchPathForDirectoriesInDomains(
      .documentDirectory,
      .userDomainMask,
      true
    )[0] as String

    let recordingName = "recordedVoice.wav"
    let pathArray = [dirPath, recordingName]
    let filePath = URL(string: pathArray.joined(separator: "/"))

    let session = AVAudioSession.sharedInstance()

    try? session.setCategory(
      AVAudioSession.Category.playAndRecord,
      mode: AVAudioSession.Mode.default,
      options: AVAudioSession.CategoryOptions.defaultToSpeaker
    )

    try? audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
    audioRecorder.delegate = self
    audioRecorder.isMeteringEnabled = true
    audioRecorder.prepareToRecord()
    audioRecorder.record()

    recordingState(false)
  }
}

extension RecordSoundViewController: AVAudioRecorderDelegate {

  enum RecordingState { case recording, notRecording }

  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    if flag {
      performSegue(withIdentifier: "stopRecording", sender: audioRecorder.url)
    } else {
      print("recording wasn't successful")
    }
  }

  func recordingState(_ enabled: Bool) {
    recordingLabel.text = enabled ?  "Tab to Record" : "Recording in progress"
    recordButton.isEnabled = enabled
    stopRecordingButton.isEnabled = !enabled
  }
}
