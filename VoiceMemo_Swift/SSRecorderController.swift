//
//  MIT License
//
//  Converted 2015 to swift 2 XBeta5 by Justin Winter http://wintercreative.com
//  Copyright (c) 2014 Bob McCune http://bobmccune.com/
//  Copyright (c) 2014 TapHarmonic, LLC http://tapharmonic.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import AVFoundation

protocol SSRecorderControllerDelegate {
  func interruptionBegan()
}

class SSRecorderController: NSObject {
  
  var player: AVAudioPlayer? = nil
  var recorder: AVAudioRecorder!
  let meterTable = SSMeterTable()
  
  var delegate: SSRecorderControllerDelegate?
  
  
  // ============================================
  // MARK: -  Initializers
  
  override init(){
    super.init()
    
    setSessionPlayback()
    
    let tmpDir = NSTemporaryDirectory()
    
    let filePath = tmpDir.stringByAppendingString("clip.m4a")
    let fileURL = NSURL.fileURLWithPath(filePath)

    let recordSettings = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 48000.0 as NSNumber,
      AVNumberOfChannelsKey: 1 as NSNumber,
      AVEncoderBitDepthHintKey: 16 as NSNumber,
      AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
    ]
    
    do {
      recorder = try AVAudioRecorder(URL: fileURL, settings: recordSettings)
      recorder.delegate = self
      recorder.meteringEnabled = true
      recorder.prepareToRecord()
      
    } catch {
      fatalError("Could not create AVAudioRecorder instance. error: \(error) : \(__FUNCTION__).")
    }
  }
  
  
  // ============================================
  // MARK: -  Imperitives
  
  
  func record(){
    let session:AVAudioSession = AVAudioSession.sharedInstance()
    // ios 8 and later
    if (session.respondsToSelector("requestRecordPermission:")) {
      
      AVAudioSession.sharedInstance().requestRecordPermission({ granted in
        if granted {
          print("Permission to record granted")
          self.setSessionPlayAndRecord()
          
          self.recorder.record()
        } else {
          print("Permission to record not granted")
        }
      })
    } else {
      print("requestRecordPermission unrecognized")
    }
  }
  
  func pause() {
    recorder.pause()
  }
  
  func saveRecordingWithName(name:String) -> String {
    
    let format = NSDateFormatter()
    format.dateFormat="yyyy-MM-dd-HH-mm-ss"
    
    let filename = "\(name)-\(format.stringFromDate(NSDate())).m4a"
    
    let srcURL = recorder.url
    let destURL = documentsDirectory().URLByAppendingPathComponent(filename)
    
    print(destURL, appendNewline: true)
    
    do {
      try NSFileManager.defaultManager().copyItemAtURL(srcURL, toURL: destURL)
      
      recorder.prepareToRecord()
      
      return destURL.pathComponents?.last ?? ""
      
    } catch {
      fatalError("Could not copyItemAtPath: \(error) : \(__FUNCTION__).")
    }
  }

  func documentsDirectory() -> NSURL {
    let manager = NSFileManager.defaultManager()
    return manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
  }
  
  func levels() -> SSLevelPair {
    recorder.updateMeters()
    let avgPower = recorder.averagePowerForChannel(0)
    let peakPower = recorder.peakPowerForChannel(0)
    let linearLevel = meterTable.valueForPower(avgPower)
    let linearPeak = meterTable.valueForPower(peakPower)
    return SSLevelPair(level: linearLevel, peakLevel: linearPeak)
  }
  
  func formattedCurrentTime() -> String {
    let time = Int(self.recorder.currentTime)
    let hours = (time/3600)
    let minutes = (time/60) % 60
    let seconds = time % 60
    
    return NSString(format: "%02i:%02i:%02i", hours, minutes, seconds) as String
  }
  
  func playbackMemo(memo:SSMemo) -> Bool {
    player?.stop()
    
    let url = documentsDirectory().URLByAppendingPathComponent(memo.filename)
    do {
      player = try AVAudioPlayer(contentsOfURL: url)
    } catch {
      print(url, appendNewline: true)
      fatalError("Could not init AVAudioPlayer: \(error) : \(__FUNCTION__).")
    }
    
    player?.play()
    return true
  }
  
  func audioRecorderBeginInterruption(recorder: AVAudioRecorder) {
    delegate?.interruptionBegan()
  }
  
  func setSessionPlayback() {
    let session:AVAudioSession = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(AVAudioSessionCategoryPlayback)
    }
    catch let e as NSError {
      print(e.localizedDescription)
    }
    
    do {
      try session.setActive(true)
    }
    catch let e as NSError {
      print("could not make session active")
      print(e.localizedDescription)
    }
  }
  
  func setSessionPlayAndRecord() {
    let session:AVAudioSession = AVAudioSession.sharedInstance()
    
    do {
      try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
    }
    catch let e as NSError {
      print(e.localizedDescription)
    }
    
    do {
      try session.setActive(true)
    }
    catch let e as NSError {
      print("could not make session active")
      print(e.localizedDescription)
    }
  }

}

extension SSRecorderController: AVAudioRecorderDelegate {
  func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
    recorder.stop()
  }
}