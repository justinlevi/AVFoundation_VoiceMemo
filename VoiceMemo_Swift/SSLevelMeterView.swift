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
import Foundation

class SSLevelMeterView: UIView {
  
  let ledCount = 20
  let ledBackgroundColor = UIColor(white: 0, alpha: 0.35)
  let ledBorderColor = UIColor.blackColor()
  
  var colorThresholds = [SSLevelMeterColorThreshold]()
  var level:Float = 0.0
  var peakLevel:Float = 0.0
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    setupView()
  }
  
  func setupView(){
    backgroundColor = UIColor.clearColor()
    
    let greenColor = UIColor(red:0.458, green:1, blue:0.396, alpha:1)
    let yellowColor = UIColor(red:1, green:0.930, blue:0.315, alpha:1)
    let redColor = UIColor(red:1, green:0.325, blue:0.329, alpha:1)
    
    colorThresholds = [
      SSLevelMeterColorThreshold(maxValue: 0.5, color: greenColor, name: "green"),
      SSLevelMeterColorThreshold(maxValue: 0.8, color: yellowColor, name: "yellow"),
      SSLevelMeterColorThreshold(maxValue: 1.0, color: redColor, name: "red")]
  }
  
  override func drawRect(rect: CGRect) {
    let context = UIGraphicsGetCurrentContext()
    
    CGContextTranslateCTM(context, 0, CGRectGetHeight(self.bounds))
    CGContextRotateCTM(context, CGFloat(-M_PI_2))
    let bounds = CGRectMake(0, 0, self.bounds.size.height, self.bounds.size.width)
    
    var lightMinValue:Float = 0.0
    
    var peakLED = -1
    
    if peakLevel > 0 {
      peakLED = Int(peakLevel) * ledCount
      if peakLED >= ledCount {
        peakLED = ledCount - 1
      }
    }
    
    for ledIndex in 0..<ledCount{
      
      var ledColor = colorThresholds[0].color
      
      let ledMaxValue = Float(ledIndex + 1) / Float(ledCount)
      
      for colorIndex in 0..<colorThresholds.count-1 {
        let currentThreshold = colorThresholds[colorIndex]
        let nextThreshold = colorThresholds[colorIndex + 1]
        if currentThreshold.maxValue <= ledMaxValue {
          ledColor = nextThreshold.color
        }
      }
      
      let height = CGRectGetHeight(bounds)
      let width = CGRectGetWidth(bounds)
      
      let ledRect = CGRectMake(0, height * CGFloat(ledIndex) / CGFloat(ledCount), width, height * (1.0 / CGFloat(ledCount)))
      
      // Fill background color
      CGContextSetFillColorWithColor(context, ledBackgroundColor.CGColor)
      CGContextFillRect(context, ledRect)
      
      // Draw Light
      //let lightIntensity = (ledIndex == peakLED) ? 1 : clamp(CGFloat((level - lightMinValue) / (ledMaxValue - lightMinValue)))
      
      let lightIntensity: CGFloat
      if (ledIndex == peakLED) {
        lightIntensity = 1.0
      }else{
        lightIntensity = clamp(CGFloat((level - lightMinValue) / (ledMaxValue - lightMinValue)))
      }
      
      var fillColor: UIColor?
      if (lightIntensity == 1.0) {
        fillColor = ledColor
      } else if (lightIntensity > 0) {
        let color = CGColorCreateCopyWithAlpha(ledColor.CGColor, lightIntensity)
        fillColor = UIColor(CGColor: color!)
      }
      
      CGContextSetFillColorWithColor(context, fillColor?.CGColor)
      
      let fillPath = UIBezierPath(roundedRect: ledRect, cornerRadius: 2)
      CGContextAddPath(context, fillPath.CGPath)
      
      // Stroke border
      
      CGContextSetStrokeColorWithColor(context, ledBorderColor.CGColor)
      let strokePath = UIBezierPath(roundedRect: CGRectInset(ledRect, 0.5, 0.5), cornerRadius: 2)
      CGContextAddPath(context, strokePath.CGPath)
      
      CGContextDrawPath(context, .FillStroke)
      
      lightMinValue = ledMaxValue
    }
  }

  func clamp(intensity:CGFloat) -> CGFloat {
    if (intensity < 0) {
      return 0;
    } else if (intensity >= 1) {
      return 1;
    } else {
      return intensity;
    }
  }
  
  func resetLevelMeter(){
    level = 0
    peakLevel = 0
    self.setNeedsDisplay()
  }
}
