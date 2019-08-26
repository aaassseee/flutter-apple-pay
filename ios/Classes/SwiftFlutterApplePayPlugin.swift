import Flutter
import UIKit
import Foundation
import PassKit
import Stripe

typealias AuthorizationCompletion = (_ payment: String) -> Void
typealias AuthorizationViewControllerDidFinish = (_ error : NSDictionary) -> Void
#if __IPHONE_11_0
typealias CompletionHandler = (PKPaymentAuthorizationResult) -> Void
#else
typealias CompletionHandler = (PKPaymentAuthorizationStatus) -> Void
#endif

public class SwiftFlutterApplePayPlugin: NSObject, FlutterPlugin, PKPaymentAuthorizationViewControllerDelegate {
    var authorizationCompletion : AuthorizationCompletion!
    var authorizationViewControllerDidFinish : AuthorizationViewControllerDidFinish!
    var pkrequest = PKPaymentRequest()
    var flutterResult: FlutterResult!;
    var completionHandler: CompletionHandler!
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_apple_pay", binaryMessenger: registrar.messenger())
        registrar.register(ApplaPayButtonFactory(), withId: "apple_pay_button")
        registrar.addMethodCallDelegate(SwiftFlutterApplePayPlugin(), channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getStripeToken" {
            flutterResult = result;
            let parameters = NSMutableDictionary()
            var payments: [PKPaymentNetwork] = []
            #if __IPHONE_11_0
            var shippingFields: Set<PKContactField> = []
            #else
            var shippingFields: PKAddressField = []
            #endif
            
            var items = [PKPaymentSummaryItem]()
            var totalPrice:Double = 0.0
            let arguments = call.arguments as! NSDictionary
            
            guard let paymentNeworks = arguments["paymentNetworks"] as? [String] else {return}
            guard let countryCode = arguments["countryCode"] as? String else {return}
            guard let currencyCode = arguments["currencyCode"] as? String else {return}
            
            guard let stripePublishedKey = arguments["stripePublishedKey"] as? String else {return}
            guard let paymentItems = arguments["paymentItems"] as? [NSDictionary] else {return}
            guard let merchantIdentifier = arguments["merchantIdentifier"] as? String else {return}
            guard let merchantName = arguments["merchantName"] as? String else {return}
            let requiredShippingContactFields = arguments["requiredShippingContactFields"] as? [String]
            
            for dictionary in paymentItems {
                guard let label = dictionary["label"] as? String else {return}
                guard let price = dictionary["amount"] as? Double else {return}
                totalPrice += price
                if #available(iOS 9.0, *) {
                    let type = PKPaymentSummaryItemType.final
                    items.append(PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(floatLiteral: price), type: type))
                } else {
                    items.append(PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(floatLiteral: price)))
                }
            }
            
            Stripe.setDefaultPublishableKey(stripePublishedKey)
            let total : PKPaymentSummaryItem
            if #available(iOS 9.0, *) {
                total = PKPaymentSummaryItem(label: merchantName, amount: NSDecimalNumber(floatLiteral:totalPrice), type: .final)
            } else {
                total = PKPaymentSummaryItem(label: merchantName, amount: NSDecimalNumber(floatLiteral:totalPrice))
            }
            items.append(total)
            
            paymentNeworks.forEach {
                
                guard let paymentType = PaymentSystem(rawValue: $0) else {
                    assertionFailure("No payment type found")
                    return
                }
                
                if(paymentType.paymentNetwork != nil) {
                    payments.append(paymentType.paymentNetwork!)
                }
            }
            
            requiredShippingContactFields?.forEach{
                guard let shippingFieldType = ShippingFields(rawValue: $0) else {
                    assertionFailure("No shipping field type found")
                    return
                }
                
                if(shippingFieldType.shippingField != nil) {
                    shippingFields.insert(shippingFieldType.shippingField!)
                }
            }
            
            parameters["paymentNetworks"] = payments
            parameters["requiredShippingContactFields"] = shippingFields
            parameters["merchantCapabilities"] = PKMerchantCapability.capability3DS // optional
            
            parameters["merchantIdentifier"] = merchantIdentifier
            parameters["countryCode"] = countryCode
            parameters["currencyCode"] = currencyCode
            
            parameters["paymentSummaryItems"] = items
            
            makePaymentRequest(parameters: parameters,  authCompletion: authorizationCompletion, authControllerCompletion: authorizationViewControllerDidFinish)
        }
        else if call.method == "closeApplePaySheetWithSuccess" {
            closeApplePaySheetWithSuccess()
        }
        else if call.method == "closeApplePaySheetWithError" {
            closeApplePaySheetWithError()
        }  else {
            result("Flutter method not implemented on iOS")
        }
    }
    
    func authorizationCompletion(_ payment: String) {
        // success
        //        var result: [String: Any] = [:]
        //
        //        result["token"] = payment.token.transactionIdentifier
        //        result["billingContact"] = payment.billingContact?.emailAddress
        //        result["shippingContact"] = payment.shippingContact?.emailAddress
        //        result["shippingMethod"] = payment.shippingMethod?.detail
        //
        flutterResult(payment)
    }
    
    func authorizationViewControllerDidFinish(_ error : NSDictionary) {
        //error
        flutterResult(error)
    }
    
    enum PaymentSystem: String {
        case visa
        case mastercard
        case amex
        case quicPay
        case chinaUnionPay
        case discover
        case interac
        case privateLabel
        
        var paymentNetwork: PKPaymentNetwork? {
            
            switch self {
            case .mastercard: return PKPaymentNetwork.masterCard
            case .visa: return PKPaymentNetwork.visa
            case .amex: return PKPaymentNetwork.amex
                #if __IPHONE_9_0
            case .discover: return PKPaymentNetwork.discover
            case .privateLabel: return PKPaymentNetwork.privateLabel
                #endif
                #if __IPHONE_9_2
            case .chinaUnionPay: return PKPaymentNetwork.chinaUnionPay
            case .interac: return PKPaymentNetwork.interac
                #endif
                #if __IPHONE_10_3
            case .quicPay: return PKPaymentNetwork.quicPay
                #endif
            default: return nil
            }
        }
    }
    
    #if __IPHONE_11_0
    enum ShippingFields: String {
        case postalAddress
        case emailAddress
        case phoneNumber
        case name
        case phoneticName
        
        var shippingField: PKContactField {
            
            switch self {
            case .postalAddress: return PKContactField.postalAddress
            case .emailAddress: return PKContactField.emailAddress
            case .phoneNumber: return PKContactField.phoneNumber
            case .name: return PKContactField.name
            case .phoneticName: return PKContactField.phoneticName
            }
        }
    }
    #else
    enum ShippingFields: String {
        case postalAddress
        case emailAddress
        case phoneNumber
        case name
        case phoneticName
        
        var shippingField: PKAddressField? {
            
            switch self {
            case .postalAddress: return PKAddressField.postalAddress
            case .emailAddress: return PKAddressField.email
            case .phoneNumber: return PKAddressField.phone
            #if __IPHONE_8_3
            case .name: return PKAddressField.name
            #endif
            case .phoneticName: return PKAddressField.phone
            default: return nil
            }
        }
    }
    #endif
    
    func makePaymentRequest(parameters: NSDictionary, authCompletion: @escaping AuthorizationCompletion, authControllerCompletion: @escaping AuthorizationViewControllerDidFinish) {
        guard let paymentNetworks               = parameters["paymentNetworks"]                 as? [PKPaymentNetwork] else {return}
        #if __IPHONE_11_0
        guard let requiredShippingContactFields = parameters["requiredShippingContactFields"]   as? Set<PKContactField> else {return}
        #else
        guard let requiredShippingAddressFields = parameters["requiredShippingContactFields"]   as? PKAddressField else {return}
        #endif
        let merchantCapabilities : PKMerchantCapability = parameters["merchantCapabilities"]    as? PKMerchantCapability ?? .capability3DS
        
        guard let merchantIdentifier            = parameters["merchantIdentifier"]              as? String else {return}
        guard let countryCode                   = parameters["countryCode"]                     as? String else {return}
        guard let currencyCode                  = parameters["currencyCode"]                    as? String else {return}
        
        guard let paymentSummaryItems           = parameters["paymentSummaryItems"]             as? [PKPaymentSummaryItem] else {return}
        
        authorizationCompletion = authCompletion
        authorizationViewControllerDidFinish = authControllerCompletion
        
        // Cards that should be accepted
        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
            
            pkrequest.merchantIdentifier = merchantIdentifier
            pkrequest.countryCode = countryCode
            pkrequest.currencyCode = currencyCode
            pkrequest.supportedNetworks = paymentNetworks
            #if __IPHONE_11_0
                if (!requiredShippingContactFields.isEmpty) {
                    pkrequest.requiredShippingContactFields = requiredShippingContactFields
                }
            #else
                if (!requiredShippingAddressFields.isEmpty) {
                    pkrequest.requiredShippingAddressFields = requiredShippingAddressFields
                }
            #endif
            
            // This is based on using Stripe
            pkrequest.merchantCapabilities = merchantCapabilities
            
            pkrequest.paymentSummaryItems = paymentSummaryItems
            
            let authorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: pkrequest)
            
            if let viewController = authorizationViewController {
                viewController.delegate = self
                guard let currentViewController = UIApplication.shared.keyWindow?.topMostViewController() else {
                    return
                }
                currentViewController.present(viewController, animated: true)
            }
        } else {
            let error: NSDictionary = ["message": "User not added some cards", "code": "404"]
            authControllerCompletion(error)
        }
        
        return
    }
    
    #if __IPHONE_11_0
    public func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        
        STPAPIClient.shared().createToken(with: payment) { (stripeToken, error) in
            guard error == nil, let stripeToken = stripeToken else {
                print(error!)
                completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                return
            }
            
            self.authorizationCompletion(stripeToken.stripeID)
            self.completionHandler = completion
        }
        
    }
    #else
    public func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        
        STPAPIClient.shared().createToken(with: payment) { (stripeToken, error) in
            guard error == nil, let stripeToken = stripeToken else {
                print(error!)
                completion(PKPaymentAuthorizationStatus.failure)
                return
            }
            
            self.authorizationCompletion(stripeToken.stripeID)
            self.completionHandler = completion
        }
    }
    #endif
    
    public func closeApplePaySheetWithSuccess() {
        if (self.completionHandler != nil) {
            #if __IPHONE_11_0
                self.completionHandler(PKPaymentAuthorizationResult(status: .success, errors: nil))
            #else
                self.completionHandler(PKPaymentAuthorizationStatus.success)
            #endif
        }
    }
    
    public func closeApplePaySheetWithError() {
        if (self.completionHandler != nil) {
            #if __IPHONE_11_0
                self.completionHandler(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            #else
                self.completionHandler(PKPaymentAuthorizationStatus.failure)
            #endif
        }
    }
    
    public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        // Dismiss the Apple Pay UI
        guard let currentViewController = UIApplication.shared.keyWindow?.topMostViewController() else {
            return
        }
        currentViewController.dismiss(animated: true, completion: nil)
        let error: NSDictionary = ["message": "User closed apple pay", "code": "400"]
        authorizationViewControllerDidFinish(error)
    }
    
    func makePaymentSummaryItems(itemsParameters: Array<Dictionary <String, Any>>) -> [PKPaymentSummaryItem]? {
        var items = [PKPaymentSummaryItem]()
        var totalPrice:Decimal = 0.0
        
        for dictionary in itemsParameters {
            
            guard let label = dictionary["label"] as? String else {return nil}
            guard let amount = dictionary["amount"] as? NSDecimalNumber else {return nil}
            #if __IPHONE_9_0
            guard let type = dictionary["type"] as? PKPaymentSummaryItemType else {return nil}
            #endif
            
            totalPrice += amount.decimalValue
            
            #if __IPHONE_9_0
            items.append(PKPaymentSummaryItem(label: label, amount: amount, type: type))
            #else
            items.append(PKPaymentSummaryItem(label: label, amount: amount))
            #endif
        }
        
        let total : PKPaymentSummaryItem
        #if __IPHONE_9_0
        total = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal:totalPrice), type: .final)
        #else
        total = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal:totalPrice))
        #endif
        items.append(total)
        print(items)
        return items
    }
    
}

extension UIWindow {
    func topMostViewController() -> UIViewController? {
        guard let rootViewController = self.rootViewController else {
            return nil
        }
        return topViewController(for: rootViewController)
    }
    
    func topViewController(for rootViewController: UIViewController?) -> UIViewController? {
        guard let rootViewController = rootViewController else {
            return nil
        }
        guard let presentedViewController = rootViewController.presentedViewController else {
            return rootViewController
        }
        switch presentedViewController {
        case is UINavigationController:
            let navigationController = presentedViewController as! UINavigationController
            return topViewController(for: navigationController.viewControllers.last)
        case is UITabBarController:
            let tabBarController = presentedViewController as! UITabBarController
            return topViewController(for: tabBarController.selectedViewController)
        default:
            return topViewController(for: presentedViewController)
        }
    }
}
