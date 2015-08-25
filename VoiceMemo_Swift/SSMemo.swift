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

import Foundation

struct SSMemo {
  var title: String
  var filename: String
  var dateString: String
  var timeString: String
  
  init(title:String, filename:String){
    self.title = title
    self.filename = filename
    
    let date = NSDate()
    
    let formatter = NSDateFormatter()
    
    formatter.dateFormat = "MMddyyyy"
    self.dateString = formatter.stringFromDate(date)
    
    formatter.dateFormat = "HHmmss"
    self.timeString = formatter.stringFromDate(date)
  }
  
  init(title:String, filename:String, dateString:String, timeString:String){
    self.title = title
    self.filename = filename
    self.dateString = dateString
    self.timeString = timeString
  }
  
  func deleteMemo() -> Bool {
    do{
      try NSFileManager.defaultManager().removeItemAtURL(documentsDirectory().URLByAppendingPathComponent(self.filename))
      return true
    }catch{
      fatalError("Unable to delete: \(error) : \(__FUNCTION__).")
    }
  }
  
  func documentsDirectory() -> NSURL {
    let manager = NSFileManager.defaultManager()
    return manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
  }
  
  func dateStringWithDate(date: NSDate) -> String {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "MMddyyyy"
    return formatter.stringFromDate(date)
  }
  

  func timeStringWithDate(date: NSDate) -> String {
    let formatter =  NSDateFormatter()
    formatter.dateFormat = "HHmmss"
    return formatter.stringFromDate(date)
  }
  
  func asDictionary() -> [String:AnyObject]{
    return ["title": title, "filename": filename, "dateString": dateString, "timeString": timeString]
  }
}