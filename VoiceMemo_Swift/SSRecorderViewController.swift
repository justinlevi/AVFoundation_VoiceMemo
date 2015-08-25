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

class SSRecorderViewController: UIViewController {
  
  let kMemoCell = "memoCell"
  let kMemosArchive = "memos.archive"
  
  // ============================================
  // MARK: -  Properties

  let controller = SSRecorderController()
  
  var levelTimer: CADisplayLink? = nil
  var timer: NSTimer? = nil
  var memos = [SSMemo]()
  
  
  // ============================================
  // MARK: -  Outlets

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var levelMeterView: SSLevelMeterView!
  
  
  // ============================================
  // MARK: -  Actions
  
  @IBAction func record(sender: UIButton) {
    stopButton.enabled = true
    if !sender.selected {
      startMeterTimer()
      startTimer()
      controller.record()
    }else{
      stopMeterTimer()
      stopTimer()
      controller.pause()
    }
    sender.selected = !sender.selected
  }
  
  func startTimer(){
    timer?.invalidate()
    timer = NSTimer(timeInterval: 0.5, target: self, selector: Selector("updateTimeDisplay"), userInfo: nil, repeats: true)
    NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
  }
  
  func updateTimeDisplay(){
    timeLabel.text = controller.formattedCurrentTime()
  }
  
  func stopTimer(){
    timer?.invalidate()
    timer = nil
  }
  
  @IBAction func stopRecording(sender: UIButton) {
    stopMeterTimer()
    recordButton.selected = false
    stopButton.enabled = false
    
    controller.recorder.stop()
    
    runMain(after: 0.01) {
      let alertController = UIAlertController(title: "Save Recording", message: "Please provide a name", preferredStyle: .Alert)
      alertController.addTextFieldWithConfigurationHandler({ textField in
        textField.placeholder = "My Recording"
      })
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .Destructive, handler: nil)
      let okAction = UIAlertAction(title: "OK", style: .Default, handler: { _ in
        let name = alertController.textFields![0] as UITextField
        let urlEncodedName = self.controller.saveRecordingWithName(name.text!)
        
        self.memos.append(SSMemo(title: name.text!, filename: urlEncodedName))
        
        self.saveMemos()
        self.tableView.reloadData()
      })
      
      alertController.addAction(cancelAction)
      alertController.addAction(okAction)

      self.presentViewController(alertController, animated: true, completion: nil)
    }
  }
  
  // ============================================
  // MARK: -  ViewController LifeCycle
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()

    controller.delegate = self
    stopButton.enabled = false
    
    let data = NSData(contentsOfURL: archiveURL())
    if let data = data {
      do {
        let jsonObject:[AnyObject] = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! [AnyObject]
        for memo in jsonObject {
          memos.append(SSMemo(
            title: memo["title"] as! String,
            filename: memo["filename"] as! String,
            dateString: memo["dateString"] as! String,
            timeString: memo["timeString"] as! String))
        }
      }catch{
        fatalError("Unable to create JSONObjectWithDate: \(error) : \(__FUNCTION__).")
      }
    }
  }
  
  // ============================================
  // MARK: -  Memo Archiving
  
  func saveMemos(){
    
    if NSFileManager.defaultManager().fileExistsAtPath(archiveURL().path!) {
      do {
        try NSFileManager.defaultManager().removeItemAtPath(archiveURL().path!)
      }catch{
        fatalError("Unable to delete file: \(error) : \(__FUNCTION__).")
      }
    }
    
    do {
      let dictArr = memos.map({($0 as SSMemo).asDictionary() as AnyObject})
      let jsonData = try NSJSONSerialization.dataWithJSONObject(dictArr, options: NSJSONWritingOptions.PrettyPrinted)
      jsonData.writeToURL(archiveURL(), atomically: true)
      
    }catch {
      fatalError("Unable to create dataWithJSONObject: \(error) : \(__FUNCTION__).")
    }
  }
  
  func archiveURL() -> NSURL {
    return controller.documentsDirectory().URLByAppendingPathComponent(kMemosArchive)
  }
  
  
  // ============================================
  // MARK: - Level Metering
  
  func startMeterTimer(){
    levelTimer?.invalidate()
    levelTimer = CADisplayLink(target: self, selector: Selector("updateMeter"))
    levelTimer?.frameInterval = 5
    levelTimer?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
  }
  
  func stopMeterTimer(){
    levelTimer?.invalidate()
    levelTimer = nil
    levelMeterView.resetLevelMeter()
  }
  
  func updateMeter(){
    let levels = controller.levels()
    levelMeterView.level = levels.level
    levelMeterView.peakLevel = levels.peakLevel
    levelMeterView.setNeedsDisplay()
  }
  
}


// ============================================
// MARK: - SSRecorderControllerDelegate Protocol Conformance

extension SSRecorderViewController: SSRecorderControllerDelegate {
  func interruptionBegan(){
    recordButton.selected = false
    stopMeterTimer()
    stopTimer()
  }
}


// ============================================
// MARK: -  UITableView Datasource and Delegate

extension SSRecorderViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return memos.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(kMemoCell, forIndexPath: indexPath) as! SSMemoCell
    let memo = memos[indexPath.row]
    cell.titleLabel.text = memo.title
    cell.dateLabel.text = memo.dateString
    cell.timeLabel.text = memo.timeString
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let memo = memos[indexPath.row]
    controller.playbackMemo(memo)
  }
  
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      let memo = memos[indexPath.row]
      memo.deleteMemo()
      memos.removeAtIndex(indexPath.row)
      
      self.saveMemos()
      self.tableView.reloadData()
    }
  }
}