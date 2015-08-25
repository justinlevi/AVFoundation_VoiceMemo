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

class SSMeterTable: NSObject {
  
  let kMinDB:Float = -60.0
  let kTableSize:Float = 300.0
  
  let dbResolution: Float
  let scaleFactor: Float
  
  var meterTable = [Float]()
  
  override init() {
    
    dbResolution = kMinDB / (kTableSize - 1)
    scaleFactor = 1.0 / dbResolution
  
    let minAmp = SSMeterTable.dbToAmp(kMinDB)
    let ampRange = 1.0 - minAmp
    let invAmpRange = 1.0 / ampRange
    
    for i in 0..<Int(kTableSize){
      let decibels = Float(i) * dbResolution
      let amp = SSMeterTable.dbToAmp(decibels)
      let adjAmp = (amp - minAmp) * invAmpRange
      meterTable.append(Float(adjAmp))
    }
    
    super.init()
  }
  
  class func dbToAmp(db:Float) -> Float{
    return powf(Float(10.0), Float(0.05 * db))
  }
  
  
  func valueForPower(power:Float) -> Float {
    if power < kMinDB {
      return 0
    } else if (power >= 0) {
      return 1
    } else {
      let index = Int(power * scaleFactor)
      return meterTable[index]
    }
  }
}
