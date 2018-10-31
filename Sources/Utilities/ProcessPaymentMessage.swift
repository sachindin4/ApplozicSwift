//
//  ProcessPaymentMessage.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 24/09/18.
//

import Foundation
import Applozic

open class ProcessPaymentMessage:NSObject {
    
    public override init() {
        
    }
    
    func updatePaymentMessage(paymentJSON: [AnyHashable: Any]) {
        let messsageService = ALMessageService();
        let messagedb = ALMessageDBService();
        var nsmutable = NSMutableDictionary();
        if let key = paymentJSON["parentMessageKey"] as? String{
            guard let message = messagedb.getMessage("key", value: key) else {
                return
            }
            guard let nsmutable = (message.metadata) else {
                return
            }
            
            let currentTimeInMiliseconds = Int64(Date().timeIntervalSince1970 * 1000)
            nsmutable["paymentId"] = String(currentTimeInMiliseconds)
            
            if (nsmutable["usersRequested"] != nil ) {
                nsmutable["paymentSubjectKey"]  = "Re"
                nsmutable["paymentReceiver"]  = message.to
                nsmutable[ALUserDefaultsHandler.getUserId()]  = "done"
                nsmutable.removeObject(forKey: "paymentHeader")
            }
            
            if let richMessageType = nsmutable["richMessageType"] as? String, richMessageType == "paymentMessage",
                let paymentStatus = nsmutable["paymentStatus"] as? String, paymentStatus == "paymentRequested",
                nsmutable["usersRequested"] == nil{
                
                guard let hasAccepted = paymentJSON["paymentType"] as? String else {
                    return
                }
                
                if hasAccepted == "paymentAccepted" {
                    nsmutable["paymentStatus"] = "paymentAccepted"
                    nsmutable["hiddenStatus"] = "true"
                }else {
                    nsmutable["paymentStatus"] = "paymentRejected"
                    nsmutable["hiddenStatus"] = "false"
                }
            }
            
            messsageService.updateMessageMetaData(key, withMessageMetaData: nsmutable, withCompletionHandler:{
                apiresponse, error in
                
                if error == nil {
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RefreshChatTable"), object: nil)
                    
                    let dbMessage = messagedb.getMessage("key", value: key)
                    var nsmutableMetadata = NSMutableDictionary();
                    nsmutableMetadata = (dbMessage?.metadata)!
                    
                    if nsmutableMetadata["paymentStatus"] != nil
//                        &&  nsmutableMetadata["paymentStatus"] as! String == "paymentRequested"
                    {
                        
                        nsmutableMetadata["usersRequested"] = nil;
                        
                        let message =  ALMessage();
                        
                        if(dbMessage?.groupId != nil){
                            message.groupId = dbMessage?.groupId
                        }else if(dbMessage?.contactId != nil){
                            message.contactIds = dbMessage?.contactId
                            message.to = dbMessage?.contactId
                        }
                        
                        message.key =  UUID().uuidString
                        let date = Date().timeIntervalSince1970*1000
                        message.createdAtTime = NSNumber(value: date)
                        message.sendToDevice = false
                        message.deviceKey = ALUserDefaultsHandler.getDeviceKeyString()
                        message.shared = false
                        message.fileMeta = nil
                        message.storeOnDevice = false
                        message.contentType = Int16(ALMESSAGE_CONTENT_DEFAULT)
                        message.type = "5"
                        message.source = Int16(SOURCE_IOS)
                        
                        nsmutableMetadata["paymentId"] =  nsmutableMetadata["paymentId"]
//                        nsmutableMetadata["hiddenStatus"] = "false"
                        nsmutableMetadata["richMessageType"] = "paymentMessage"
                        
                        if let paymentSubject = nsmutable["paymentSubject"] as? String {
                            nsmutableMetadata["paymentSubject"] = paymentSubject
                        }else {
                            nsmutableMetadata["paymentSubject"] = dbMessage?.metadata["paymentSubject"]
                        }
                        
                        if let parentMessageKey = nsmutable["parentMessageKey"] as? String {
                            nsmutableMetadata["parentMessageKey"] = parentMessageKey
                        }
                        
                        if let parentPaymentId = nsmutable["parentPaymentId"] as? String {
                            nsmutableMetadata["parentPaymentId"] = parentPaymentId
                        }
                        
                        if let paymentAmount = nsmutable["amount"] as? String {
                            nsmutableMetadata["amount"] = paymentAmount
                        }else {
                            nsmutableMetadata["amount"] = dbMessage?.metadata["amount"]
                        }
                        
//                        if let userReq = dbMessage?.metadata["usersRequested"] {
                            guard let hasAccepted = paymentJSON["paymentType"] as? String else {
                                return
                            }
                            if hasAccepted == "paymentAccepted" {
                                nsmutableMetadata["paymentStatus"] = "paymentAccepted"
                                nsmutableMetadata["hiddenStatus"] = "false"
                            }else {
                                nsmutableMetadata["paymentStatus"] = "paymentRejected"
                                if nsmutable["usersRequested"] == nil {
                                    nsmutableMetadata["hiddenStatus"] = "true"
                                }else {
                                    nsmutableMetadata["hiddenStatus"] = "false"
                                }
                            }
                            nsmutableMetadata["paymentSubjectKey"]  = "Re"
                            nsmutableMetadata["paymentReceiver"]  = dbMessage?.contactId
//                        }
                        
                        message.metadata = nsmutableMetadata
                        
                        ALMessageService.sendMessages(message, withCompletion: {
                            response, error in
                            
                            if(error == nil){
                                //Send status back
                                let newMsg = message
                                let paymentResponse = ALKPaymentStatus()
                                paymentResponse.code = "Success"
                                paymentResponse.messageKey = newMsg.key
                                paymentResponse.paymentStatus = paymentJSON["paymentType"] as? String
                                
                                if let parentMsgKey = paymentJSON["parentMessageKey"] as? String {
                                    paymentResponse.parentMessageKey = parentMsgKey
                                }
                                
                                if let parentPaymentID = paymentJSON["parentPaymentId"] as? String {
                                    paymentResponse.parentPaymentId = parentPaymentID
                                }
                                
                                if let paymentID = paymentJSON["paymentId"] as? String {
                                    paymentResponse.paymentId = paymentID
                                }
                                
                                let dict = ["paymentMessage": paymentResponse.toString()]
                                
                                let jsonObject: NSMutableDictionary = NSMutableDictionary()
                                let jsonData: Data
                                
                                dict.forEach { (arg) in
                                    jsonObject.setValue(arg.value, forKey: arg.key)
                                }
                                
                                do {
                                    jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                                    BroadcastToIonic.sendBroadcast(name: "paymentCallback", data: dict)
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RefreshChatTable"), object: nil)
                                } catch {
                                    assertionFailure("JSON data creation failed with error: \(error).")
                                    return
                                }
                            }
                        })
                        
                    }
                    
                }
            })
        }
    }
    
    @objc public func sendPaymentMessage(paymentJSON: [AnyHashable: Any]) {
        
        if let cancelFlag = paymentJSON["cancelFlag"] as? Bool, cancelFlag {
            return
        }
        
        if let cancelFlag = paymentJSON["cancelFlag"] as? String, cancelFlag.caseInsensitiveCompare("true") == ComparisonResult.orderedSame{
            return
        }
        
        if let paymentResponse = paymentJSON["parentMessageKey"] {
            updatePaymentMessage(paymentJSON: paymentJSON)
            return
        }
        
        let nsmutable = NSMutableDictionary()
        nsmutable["richMessageType"] = "paymentMessage"
        
        let alMessage = ALMessage()
        
        if let groupIdOptional = paymentJSON["groupId"] as? String, let groupIdInt = Int(groupIdOptional) {
            let groupId = NSNumber(value:groupIdInt)
            alMessage.groupId = groupId
            if let usersRequested = paymentJSON["userRequested"] as? NSArray{
                var userReqString = "["
                userReqString += "\""
                userReqString += usersRequested[0] as! String
                userReqString += "\""
                
                for i in (1..<usersRequested.count) {
                    userReqString += ",\""
                    userReqString += usersRequested[i] as! String
                    userReqString += "\""
                }
                userReqString += "]"
                nsmutable["usersRequested"] = userReqString
            }
        }else if let contactId = paymentJSON["userId"] as? String{
            alMessage.to = contactId
            alMessage.contactIds = contactId
        }
        
        alMessage.type = "5"
        let date = Date().timeIntervalSince1970*1000
        alMessage.createdAtTime = NSNumber(value: date)
        alMessage.sendToDevice = false
        alMessage.deviceKey = ALUserDefaultsHandler.getDeviceKeyString()
        alMessage.shared = false
        alMessage.storeOnDevice = false
        alMessage.contentType = Int16(ALMESSAGE_CONTENT_DEFAULT)
        alMessage.key = UUID().uuidString
        alMessage.source = Int16(SOURCE_IOS)
        
        if let paymentSubject = paymentJSON["paymentSubject"] as? String {
            nsmutable["paymentSubject"] = paymentSubject
        }
        
        if let paymentAmount = paymentJSON["paymentAmount"] as? String {
            nsmutable["amount"] = paymentAmount
        }
        
        if let paymentType = paymentJSON["paymentType"] as? String {
            nsmutable["paymentStatus"] = paymentType
        }
        
        let currentTimeInMiliseconds = Int64(Date().timeIntervalSince1970 * 1000)
        nsmutable["paymentId"] = String(currentTimeInMiliseconds)
        nsmutable["hiddenStatus"] = "false"
        
        alMessage.metadata = nsmutable
        
        ALMessageService.sendMessages(alMessage, withCompletion: {
            message, error in
            
            if(error == nil){
                //send Status
                let newMsg = alMessage
                
                let paymentResponse = ALKPaymentStatus()
                paymentResponse.code = "Success"
                paymentResponse.messageKey = newMsg.key
                if let paymentStatus = paymentJSON["paymentType"] as? String {
                    paymentResponse.paymentStatus = paymentStatus
                }
                
                if let parentMsgKey = paymentJSON["parentMessageKey"] as? String {
                    paymentResponse.parentMessageKey = parentMsgKey
                }
                
                if let parentPaymentID = paymentJSON["parentPaymentId"] as? String {
                    paymentResponse.parentPaymentId = parentPaymentID
                }
                
                if let paymentID = paymentJSON["paymentId"] as? String {
                    paymentResponse.paymentId = paymentID
                }
                
                let dict = ["paymentMessage": paymentResponse.toString()]
                
                let jsonObject: NSMutableDictionary = NSMutableDictionary()
                let jsonData: Data
                
                dict.forEach { (arg) in
                    jsonObject.setValue(arg.value, forKey: arg.key)
                }
                
                do {
                    jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                    BroadcastToIonic.sendBroadcast(name: "paymentCallback", data: dict)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RefreshChatTable"), object: nil)
                } catch {
                    assertionFailure("JSON data creation failed with error: \(error).")
                    return
                }
            }else {
                print("Error sending message \(error)")
            }
            
        })
        
    }
    
    public func sendPaymentMessageFrom(paymentJSON: [AnyHashable: Any]) -> ALMessage{
        
        let nsmutable = NSMutableDictionary()
        nsmutable["richMessageType"] = "paymentMessage"
        
        let alMessage = ALMessage()
        
        if let groupIdOptional = paymentJSON["groupId"] as? String, let groupIdInt = Int(groupIdOptional) {
            let groupId = NSNumber(value:groupIdInt)
            alMessage.groupId = groupId
            if let usersRequested = paymentJSON["userRequested"] as? NSArray{
                var userReqString = "["
                userReqString += "\""
                userReqString += usersRequested[0] as! String
                userReqString += "\""
                
                for i in (1..<usersRequested.count) {
                    userReqString += ",\""
                    userReqString += usersRequested[i] as! String
                    userReqString += "\""
                }
                userReqString += "]"
                nsmutable["usersRequested"] = userReqString
            }
        }else if let contactId = paymentJSON["userId"] as? String{
            alMessage.to = contactId
            alMessage.contactIds = contactId
        }
        
        alMessage.type = "5"
        let date = Date().timeIntervalSince1970*1000
        alMessage.createdAtTime = NSNumber(value: date)
        alMessage.sendToDevice = false
        alMessage.deviceKey = ALUserDefaultsHandler.getDeviceKeyString()
        alMessage.shared = false
        alMessage.storeOnDevice = false
        alMessage.contentType = Int16(ALMESSAGE_CONTENT_DEFAULT)
        alMessage.key = UUID().uuidString
        alMessage.source = Int16(SOURCE_IOS)
        
        if let paymentSubject = paymentJSON["paymentSubject"] as? String {
            nsmutable["paymentSubject"] = paymentSubject
        }
        
        if let paymentAmount = paymentJSON["paymentAmount"] as? String {
            nsmutable["amount"] = paymentAmount
        }
        
        if let paymentType = paymentJSON["paymentType"] as? String {
            nsmutable["paymentStatus"] = paymentType
        }
        
        let currentTimeInMiliseconds = Int64(Date().timeIntervalSince1970 * 1000)
        nsmutable["paymentId"] = String(currentTimeInMiliseconds)
        nsmutable["hiddenStatus"] = "false"
        
        alMessage.metadata = nsmutable
        return alMessage
    }
    
    
    func sendMessageResultToIonic(alMessage: ALMessage, paymentJSON: [AnyHashable: Any]) {
        let newMsg = alMessage
        
        let paymentResponse = ALKPaymentStatus()
        paymentResponse.code = "Success"
        paymentResponse.messageKey = newMsg.key
        if let paymentStatus = paymentJSON["paymentType"] as? String {
            paymentResponse.paymentStatus = paymentStatus
        }
        
        if let parentMsgKey = paymentJSON["parentMessageKey"] as? String {
            paymentResponse.parentMessageKey = parentMsgKey
        }
        
        if let parentPaymentID = paymentJSON["parentPaymentId"] as? String {
            paymentResponse.parentPaymentId = parentPaymentID
        }
        
        if let paymentID = paymentJSON["paymentId"] as? String {
            paymentResponse.paymentId = paymentID
        }
        
        let dict = ["paymentMessage": paymentResponse.toString()]
        
        let jsonObject: NSMutableDictionary = NSMutableDictionary()
        let jsonData: Data
        
        dict.forEach { (arg) in
            jsonObject.setValue(arg.value, forKey: arg.key)
        }
        
        do {
            jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            BroadcastToIonic.sendBroadcast(name: "paymentCallback", data: dict)
        } catch {
            assertionFailure("JSON data creation failed with error: \(error).")
            return
        }
    }
    
    func getMessageToUpdate(paymentJSON: [AnyHashable: Any], completion: @escaping (ALMessage?, NSMutableDictionary?) -> ()){
        let messsageService = ALMessageService();
        let messagedb = ALMessageDBService();
        var nsmutable = NSMutableDictionary();
        if let key = paymentJSON["parentMessageKey"] as? String{
            guard let message = messagedb.getMessage("key", value: key) else {
                completion(nil, nil)
                return
            }
            guard let nsmutable = (message.metadata) else {
                completion(nil, nil)
                return
            }
            
            let currentTimeInMiliseconds = Int64(Date().timeIntervalSince1970 * 1000)
            nsmutable["paymentId"] = String(currentTimeInMiliseconds)
            
            if (nsmutable["usersRequested"] != nil ) {
                nsmutable["paymentSubjectKey"]  = "Re"
                nsmutable["paymentReceiver"]  = message.to
                nsmutable[ALUserDefaultsHandler.getUserId()]  = "done"
                nsmutable.removeObject(forKey: "paymentHeader")
            }
            
            if let richMessageType = nsmutable["richMessageType"] as? String, richMessageType == "paymentMessage",
                let paymentStatus = nsmutable["paymentStatus"] as? String, paymentStatus == "paymentRequested",
                nsmutable["usersRequested"] == nil{
                
                guard let hasAccepted = paymentJSON["paymentType"] as? String else {
                    completion(nil, nil)
                    return
                }
                
                if hasAccepted == "paymentAccepted" {
                    nsmutable["paymentStatus"] = "paymentAccepted"
                    nsmutable["hiddenStatus"] = "true"
                }else {
                    nsmutable["paymentStatus"] = "paymentRejected"
                    nsmutable["hiddenStatus"] = "false"
                }
            }
            
            messsageService.updateMessageMetaData(key, withMessageMetaData: nsmutable, withCompletionHandler:{
                apiresponse, error in
                
                if error == nil {
                    
                    let dbMessage = messagedb.getMessage("key", value: key)
                    
                    //getMessage
                    completion(dbMessage, nsmutable)
                    
                }
            })
        }
    }
    
    public func getMessageFrom(dbMessage: ALMessage, nsmutable: NSMutableDictionary, paymentJSON: [AnyHashable: Any]) -> ALMessage?{
        
        var nsmutableMetadata = NSMutableDictionary();
        nsmutableMetadata = (dbMessage.metadata)!
        
        if nsmutableMetadata["paymentStatus"] != nil
            //                        &&  nsmutableMetadata["paymentStatus"] as! String == "paymentRequested"
        {
            
            nsmutableMetadata["usersRequested"] = nil;
            
            let message =  ALMessage();
            
            if(dbMessage.groupId != nil){
                message.groupId = dbMessage.groupId
            }else if(dbMessage.contactId != nil){
                message.contactIds = dbMessage.contactId
                message.to = dbMessage.contactId
            }
            
            message.key =  UUID().uuidString
            let date = Date().timeIntervalSince1970*1000
            message.createdAtTime = NSNumber(value: date)
            message.sendToDevice = false
            message.deviceKey = ALUserDefaultsHandler.getDeviceKeyString()
            message.shared = false
            message.fileMeta = nil
            message.storeOnDevice = false
            message.contentType = Int16(ALMESSAGE_CONTENT_DEFAULT)
            message.type = "5"
            message.source = Int16(SOURCE_IOS)
            
            nsmutableMetadata["paymentId"] =  nsmutableMetadata["paymentId"]
            //                        nsmutableMetadata["hiddenStatus"] = "false"
            nsmutableMetadata["richMessageType"] = "paymentMessage"
            
            if let paymentSubject = nsmutable["paymentSubject"] as? String {
                nsmutableMetadata["paymentSubject"] = paymentSubject
            }else {
                nsmutableMetadata["paymentSubject"] = dbMessage.metadata["paymentSubject"]
            }
            
            if let parentMessageKey = nsmutable["parentMessageKey"] as? String {
                nsmutableMetadata["parentMessageKey"] = parentMessageKey
            }
            
            if let parentPaymentId = nsmutable["parentPaymentId"] as? String {
                nsmutableMetadata["parentPaymentId"] = parentPaymentId
            }
            
            if let paymentAmount = nsmutable["amount"] as? String {
                nsmutableMetadata["amount"] = paymentAmount
            }else {
                nsmutableMetadata["amount"] = dbMessage.metadata["amount"]
            }
            
            //                        if let userReq = dbMessage?.metadata["usersRequested"] {
            guard let hasAccepted = paymentJSON["paymentType"] as? String else {
                return nil
            }
            if hasAccepted == "paymentAccepted" {
                nsmutableMetadata["paymentStatus"] = "paymentAccepted"
                nsmutableMetadata["hiddenStatus"] = "false"
            }else {
                nsmutableMetadata["paymentStatus"] = "paymentRejected"
                if nsmutable["usersRequested"] == nil {
                    nsmutableMetadata["hiddenStatus"] = "true"
                }else {
                    nsmutableMetadata["hiddenStatus"] = "false"
                }
            }
            nsmutableMetadata["paymentSubjectKey"]  = "Re"
            nsmutableMetadata["paymentReceiver"]  = dbMessage.contactId
           
            message.metadata = nsmutableMetadata
            
            return message
        }
        return nil
    }
    
    public func updatedMetadataResponseToIonic(message: ALMessage, paymentJSON: [AnyHashable: Any]) {
        //Send status back
        let newMsg = message
        let paymentResponse = ALKPaymentStatus()
        paymentResponse.code = "Success"
        paymentResponse.messageKey = newMsg.key
        paymentResponse.paymentStatus = paymentJSON["paymentType"] as? String
        
        if let parentMsgKey = paymentJSON["parentMessageKey"] as? String {
            paymentResponse.parentMessageKey = parentMsgKey
        }
        
        if let parentPaymentID = paymentJSON["parentPaymentId"] as? String {
            paymentResponse.parentPaymentId = parentPaymentID
        }
        
        if let paymentID = paymentJSON["paymentId"] as? String {
            paymentResponse.paymentId = paymentID
        }
        
        let dict = ["paymentMessage": paymentResponse.toString()]
        
        let jsonObject: NSMutableDictionary = NSMutableDictionary()
        let jsonData: Data
        
        dict.forEach { (arg) in
            jsonObject.setValue(arg.value, forKey: arg.key)
        }
        
        do {
            jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            BroadcastToIonic.sendBroadcast(name: "paymentCallback", data: dict)
        } catch {
            assertionFailure("JSON data creation failed with error: \(error).")
            return
        }
    }
    
}
