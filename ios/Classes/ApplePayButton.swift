//
//  ApplePayButtonFactory.swift
//  FlutterPackageCreationPlayground
//
//  Created by Jack Liu on 2/8/2019.
//  Copyright © 2019 Jack Liu. All rights reserved.
//

import Foundation
import PassKit
import Flutter

class ApplaPayButtonFactory : NSObject, FlutterPlatformViewFactory {
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return ApplaPayButton(frame, viewId:viewId, args:args)
    }
}

public class ApplaPayButton : NSObject, FlutterPlatformView {
    
    let frame : CGRect
    let viewId : Int64
    
    init(_ frame:CGRect, viewId:Int64, args: Any?){
        self.frame = frame
        self.viewId = viewId
    }
    
    public func view() -> UIView {
        let view : UIView
        if #available(iOS 9.0, *) {
             view = PKPaymentButton.init(paymentButtonType: .plain, paymentButtonStyle: .black)
        } else if #available(iOS 8.3, *){
            view = PKPaymentButton()
        } else {
            view = UIView()
        }
        view.frame = self.frame
        return view
    }
}
