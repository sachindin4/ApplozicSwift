//
//  ALKPaymentCell.swift
//  ApplozicSwift
//
//  Created by Sunil on 11/01/18.
//

import Kingfisher
import Foundation
import UIKit
import Applozic



public protocol ALKCustomAmountProtocol : class{
    func didAcceptCliked(paymentModel:ALKPaymentModel)
}

// MARK: - ALKPaymentCell
class ALKPaymentCell: ALKChatBaseCell<ALKMessageViewModel> {
    
    
    let Rejected: String = {
        let text = NSLocalizedString("Rejected", value: SystemMessage.PaymentMessage.Rejected, comment: "")
        return text
    }()
    let RejectedYours: String = {
        let text = NSLocalizedString("RejectedYours", value: SystemMessage.PaymentMessage.RejectedYours, comment: "")
        return text
    }()
    let Asunto: String = {
        let text = NSLocalizedString("Asunto", value: SystemMessage.PaymentMessage.Asunto, comment: "")
        return text
    }()
    let Re: String = {
        let text = NSLocalizedString("Re", value: SystemMessage.PaymentMessage.Re, comment: "")
        return text
    }()
    let RequestedFrom: String = {
        let text = NSLocalizedString("RequestedFrom", value: SystemMessage.PaymentMessage.RequestedFrom, comment: "")
        return text
    }()
    let Paid: String = {
        let text = NSLocalizedString("Paid", value: SystemMessage.PaymentMessage.Paid, comment: "")
        return text
    }()
    let You: String = {
        let text = NSLocalizedString("You", value: SystemMessage.LabelName.You, comment: "")
        return text
    }()
    
    public var delegatePr: ALKCustomAmountProtocol?
    weak public var delegate: ALKConversationViewModelDelegate?
    
    var timeLabel: UILabel = {
        let lb = UILabel()
        return lb
    }()
    
    
    fileprivate var actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        return button
    }()
    
    
    fileprivate var bubbleView: UIImageView = {
        let bv = UIImageView()
        let image = UIImage.init(named: "chat_bubble_rounded", in: Bundle.applozic, compatibleWith: nil)
        bv.tintColor = UIColor(netHex: 0xF1F0F0)
        bv.isUserInteractionEnabled = true
        bv.image = image?.imageFlippedForRightToLeftLayoutDirection()
        bv.isOpaque = true
        bv.setImageColor(color: UIColor(netHex: 0xF1F0F0))
        return bv
    }()
    
    
    var paymentTitle: PaddingLabel = {
        let lb = PaddingLabel(withInsets: 0, 0, 5, 5)
        lb.textAlignment = .center
        lb.numberOfLines = 0
        lb.font = Font.bold(size: 15.0).font()
        lb.backgroundColor=UIColor.clear
        return lb
    }()
    
    
    var paymentMoney: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .center
        lb.backgroundColor=UIColor.clear
        lb.font = Font.bold(size: 15.0).font()
        
        return lb
    }()
    
    
    var paymentSubjctTitle: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .left
        lb.font = Font.bold(size: 14.0).font()
        lb.backgroundColor = UIColor.clear
        return lb
    }()
    
    var paymentSubjctText: UILabel = {
        let lb = UILabel()
//        lb.textAlignment = .left
        lb.font = Font.bold(size: 14.0).font()
        lb.backgroundColor=UIColor.clear
        lb.numberOfLines = 0
        return lb
    }()
    
    
    
    fileprivate var paymentAceptButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("AcceptPayment", value: SystemMessage.PaymentMessage.AcceptPayment, comment: ""), for: UIControlState.normal)
        button.setTextColor(color: Color.Text.white, forState: .normal)
        return button
    }()
    
    
    fileprivate var paymentRejectButton: UIButton = {
        let button = UIButton(type: .custom)
        button .setTitle(NSLocalizedString("RefusePayment", value: SystemMessage.PaymentMessage.RefusePayment, comment: ""), for: UIControlState.normal)
        button.setTextColor(color: Color.Text.white, forState:UIControlState.normal)
        return button
    }()
    
    fileprivate lazy var paymentResponseButtons: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.paymentAceptButton, self.paymentRejectButton])
        stackView.axis = UILayoutConstraintAxis.horizontal
        stackView.distribution = UIStackViewDistribution.fillEqually
        stackView.alignment = UIStackViewAlignment.fill
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    
    fileprivate let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    var uploadTapped:((Bool) ->())?
    
    var accpetButtonTapped:((Bool) ->())?
    
    var uploadCompleted: ((_ responseDict: Any?) ->())?
    
    var downloadTapped:((Bool) ->())?
    
    
    class func topPadding() -> CGFloat {
        return 12
    }
    
    class func bottomPadding() -> CGFloat {
        return 32
    }
    
    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {
        
        var heigh = (width*0.27)
        
        //calculate height from viewModel:
        if let dict = viewModel.metadata, let paymentText = dict["paymentSubject"] as? String {
            var size = CGRect()
            //calclate exact width
            let widthNoPadding = (width * 0.4) - 30
            
            let maxSize = CGSize.init(width: widthNoPadding, height: CGFloat.greatestFiniteMagnitude)
            let font = Font.normal(size: 14).font()
            let color = UIColor.color(ALKMessageStyle.message.color)
            
            let style = NSMutableParagraphStyle.init()
            style.lineBreakMode = .byWordWrapping
            style.headIndent = 0
            style.tailIndent = 0
            style.firstLineHeadIndent = 0
            style.minimumLineHeight = 17
            style.maximumLineHeight = 17
            
            let attributes: [String : Any] = [NSFontAttributeName: font,
                                              NSForegroundColorAttributeName: color,
                                              NSParagraphStyleAttributeName: style]
            size = paymentText.boundingRect(with: maxSize, options: [NSStringDrawingOptions.usesFontLeading, NSStringDrawingOptions.usesLineFragmentOrigin],attributes: attributes, context: nil)
            let height = ceil(size.height)
            
            if height > 18.0 {
                heigh += height
            }
            if let paymentStatus = dict["paymentStatus"] as? String,
                paymentStatus.caseInsensitiveCompare("paymentRequested") == ComparisonResult.orderedSame  {
                if viewModel.channelKey == nil, viewModel.contactId != nil {
                    heigh += 20
                }else {
                    let usersRequested = dict["usersRequested"] as? String;
                    let replacedString =   usersRequested?.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]",with: "").replacingOccurrences(of: "\"",with: "")
                    
                    let arary : [String] = replacedString!.components(separatedBy: ",")
                    if arary.contains(ALUserDefaultsHandler.getUserId()) && dict[ALUserDefaultsHandler.getUserId()] == nil{
                        heigh += 20
                    }
                }
            }
        }
        
        return topPadding()+heigh+bottomPadding()
    }
    
    var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 18.5
        layer.backgroundColor = UIColor.clear.cgColor
        layer.masksToBounds = true
        return imv
    }()
    
    var rightImageView: UIImageView = {
        let imageView                   = UIImageView()
        imageView.contentMode           = .scaleAspectFill
        imageView.clipsToBounds         = true
        imageView.layer.cornerRadius    = 18.5
        imageView.layer.backgroundColor = UIColor.clear.cgColor
        imageView.layer.masksToBounds   = true
        return imageView
    }()
    
    private var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.gray
        return label
    }()
    
    var url: URL? = nil
    enum state {
        case upload(filePath: String)
        case uploading(filePath: String)
        case uploaded
        case download
        case downloading
        case downloaded(filePath: String)
    }
    
    func addPoints(inputNumber: String) -> String{
        var number = NSMutableString(string: inputNumber)
        var count: Int = number.length
        while count >= 4 {
            count = count - 3
            number.insert(".", at: count) // you also can use ","
        }
        return number as String
    }
    
    override func update(viewModel: ALKMessageViewModel) {
        self.viewModel = viewModel
        activityIndicator.color = .black
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.avatarImageView.kf.setImage(with: resource, placeholder: placeHolder, options: nil, progressBlock: nil, completionHandler: nil)
        } else {
            self.avatarImageView.image = placeHolder
        }
        nameLabel.text = viewModel.displayName
        var nsmutable =  viewModel.metadata
        
        if((nsmutable) != nil){
            let amount =     nsmutable!["amount"]
            let hiddenStatus =     nsmutable!["hiddenStatus"]
            let paymentId =     nsmutable!["paymentId"]
            let paymentMessage = nsmutable!["paymentMessage"]
            let paymentSubject = nsmutable!["paymentSubject"]
            let paymentStatus = nsmutable!["paymentStatus"]
            let richMessageType = nsmutable!["richMessageType"];
            let doller = "$"
            var amountString = "\(doller) \(amount as! String)"
            
            //This!!!! This piece of code should've worked.
            if let amountAsString = amount as? String, let amountAsInt = Int(amountAsString) {
//                let formatter = NumberFormatter()
//                formatter.groupingSeparator = "."
//                formatter.numberStyle = .decimal
//                if let amnt = formatter.string(for: amountAsInt) {
//                    amountString = "\(doller) \(amnt)"
//                }
                amountString = "\(doller) \(addPoints(inputNumber: amountAsString))"
            }
            
            if(viewModel.isMyMessage){
                if(paymentStatus != nil && "paymentRequested"  ==  paymentStatus as! String!){
                    handlePaymentActionbuttonVisibality(isHidden: false)
                    paymentMoney.text = amountString
                    paymentTitle.text = String(format: RequestedFrom, You, viewModel.displayName!)
                }else if("paymentRejected" == paymentStatus as! String!){
                    
                    let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string:                  amountString)
                    attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
                    paymentTitle.text = String(format: RejectedYours, viewModel.displayName!, "").replacingOccurrences(of: "%@", with: "")
                    paymentMoney.attributedText = attributeString
                }else{
                    handlePaymentActionbuttonVisibality(isHidden: true)
                    paymentMoney.text = amountString
                    paymentTitle.text = String(format: Paid, You, viewModel.displayName!)
                }
            }else{
                if("paymentRequested"  ==  paymentStatus as! String!){
                    if(viewModel.channelKey != nil){
                        let  channelService = ALChannelDBService();
                        let  messageDb = ALMessageDBService();
                        let requestedString = viewModel.displayName!
                        
                        if(nsmutable!["paymentHeader"] == nil){
                            let groupNames = channelService.string(fromChannelUserMetaData:NSMutableDictionary(dictionary: nsmutable!), paymentMessageTitle: true)
                            
                            nsmutable!["paymentHeader"] = groupNames
                            paymentTitle.text = String(format: RequestedFrom, requestedString, groupNames!)
                            
                            let channeldb = messageDb.updateMessageMetaData(viewModel.identifier, withMetadata:NSMutableDictionary(dictionary: nsmutable!))
                            
                        }else{
                            let YouRequestedFrom = String(format: RequestedFrom, You, "").replacingOccurrences(of: "%@", with: "")
                            if var header = nsmutable!["paymentHeader"] as? String, header.contains(YouRequestedFrom){
                                header = header.replacingOccurrences(of: YouRequestedFrom, with: "")
                                let arr = header.split(separator: ",")
                                var append: String = ""
                                if arr.count == 1 {
                                    append += " "+arr[0]
                                }else if arr.count == 2 {
                                    append += " " + arr[0] + ", " + arr[1]
                                }else {
                                    append += " " + arr[0] + ", " + arr[1] + " +\(arr.count - 2) more"
                                }
                                paymentTitle.text = String(format: RequestedFrom, requestedString, append)
                            }else {
                                paymentTitle.text = String(format: RequestedFrom, requestedString, (nsmutable!["paymentHeader"] as? String)!)
                            }
                        }
                        
                        let  paymentReceiver = nsmutable!["paymentReceiver"] as? String;
                        
                        if(paymentReceiver == nil){
                        
                            if (nsmutable![ALUserDefaultsHandler.getUserId()] != nil ){
                                handlePaymentActionbuttonVisibality(isHidden: true)
                            }else{
                                let usersRequested = nsmutable!["usersRequested"] as? String;
                                let replacedString =   usersRequested?.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]",with: "").replacingOccurrences(of: "\"",with: "")
                                
                                let arary : [String] = replacedString!.components(separatedBy: ",")
                                if arary.contains(ALUserDefaultsHandler.getUserId()){
                                    handlePaymentActionbuttonVisibality(isHidden: false)
                                }else{
                                    handlePaymentActionbuttonVisibality(isHidden: true)
                                }
                            }
                        }else if (nsmutable![ALUserDefaultsHandler.getUserId()] != nil ){
                            handlePaymentActionbuttonVisibality(isHidden: true)
                        }else{
                            handlePaymentActionbuttonVisibality(isHidden: false)
                        }
                    }else if(viewModel.contactId != nil){
                        paymentTitle.text = String(format: RequestedFrom, viewModel.displayName!, You)
                        handlePaymentActionbuttonVisibality(isHidden: false)
                    }
                    paymentMoney.text = amountString
                }else if("paymentRejected" == paymentStatus as! String!){
                    
                    let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string:  amountString)
                    attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
                    handlePaymentActionbuttonVisibality(isHidden: true)
                    paymentMoney.attributedText = attributeString
                    
                    if(viewModel.channelKey != nil){
                        
                        let  channelService = ALChannelDBService();
                        let  messageDb = ALMessageDBService();
                        if(nsmutable!["paymentHeader"] == nil){
                            let paymentReceiver =   nsmutable!["paymentReceiver"] as? String
                            if(paymentReceiver != nil){
                                let contactDataBase = ALContactDBService()
                                
                                let contact =  contactDataBase.loadContact(byKey: "userId", value: paymentReceiver);
                                if(contact != nil){
                                    var groupNames : String  = " ";
                                    if(ALUserDefaultsHandler.getUserId()  == contact?.userId){
                                        groupNames  = String(format: RejectedYours, viewModel.displayName!)
                                    }else{
                                        groupNames = String(format: Rejected, viewModel.displayName!, (contact?.getDisplayName())!)
                                    }
                                    
                                    nsmutable!["paymentHeader"] = groupNames
                                    paymentTitle.text = groupNames
                                    
                                    let channeldb = messageDb.updateMessageMetaData(viewModel.identifier, withMetadata:NSMutableDictionary(dictionary: nsmutable!) )
                                }
                            }
                        }else{
                            paymentTitle.text =  (nsmutable!["paymentHeader"] as? String)!
                        }
                    }else{
                        paymentTitle.text = String(format: Rejected, You, viewModel.displayName!)
                    }
//                    paymentResponseButtons.isHidden = true
                }else if("paymentAccepted" == paymentStatus as! String!){
                    paymentMoney.text = amountString
                    handlePaymentActionbuttonVisibality(isHidden: true)
                    var paymentReceiver =   nsmutable!["paymentReceiver"] as? String
                    if(viewModel.channelKey != nil){
                        if(paymentReceiver != nil){
                            let  channelService = ALChannelDBService();
                            let  messageDb = ALMessageDBService();
                            if(nsmutable!["paymentHeader"] == nil){
                                let contactDataBase = ALContactDBService()
                                let contact =  contactDataBase.loadContact(byKey: "userId", value: paymentReceiver);
                                var displayName = "";
                                if(paymentReceiver  ==  ALUserDefaultsHandler.getUserId()){
                                    displayName = NSLocalizedString("You", value: SystemMessage.LabelName.You, comment: "");
                                }else{
                                    displayName = (contact?.getDisplayName())!
                                }
                                if(contact != nil){
                                    let groupNames = String(format: Paid, viewModel.contactId!, displayName)
                                    nsmutable!["paymentHeader"] = groupNames
                                    paymentTitle.text = groupNames
                                    let channeldb = messageDb.updateMessageMetaData(viewModel.identifier, withMetadata:NSMutableDictionary(dictionary: nsmutable! ))
                                }
                            }else{
                                paymentTitle.text =  (nsmutable!["paymentHeader"] as? String)!
                            }
                        }else{
                            paymentTitle.text = String(format: Paid, viewModel.displayName!, You)
                        }
                    }else{
                        paymentTitle.text = String(format: Paid, viewModel.displayName!, You)
                    }
//                    paymentResponseButtons.isHidden = true
                }else{
                    let requestedString = viewModel.displayName!
                    if(viewModel.channelKey != nil){
                        let  channelService = ALChannelDBService();
                        let  messageDb = ALMessageDBService();
                        
                        if(nsmutable!["paymentHeader"] == nil){
                            let groupNames = channelService.string(fromChannelUserMetaData:NSMutableDictionary(dictionary: nsmutable!), paymentMessageTitle: true)
                            
                            nsmutable!["paymentHeader"] = groupNames
                            paymentTitle.text = String(format: Paid, requestedString, groupNames!)
                            
                            let channeldb = messageDb.updateMessageMetaData(viewModel.identifier, withMetadata:NSMutableDictionary(dictionary: nsmutable!)  )
                            
                        }else{
                            let YouPaidTo = String(format: Paid, You, "").replacingOccurrences(of: "%@", with: "")
                            if var header = nsmutable!["paymentHeader"] as? String, header.contains(YouPaidTo){
                                header = header.replacingOccurrences(of: YouPaidTo, with: "")
                                let arr = header.split(separator: ",")
                                var append: String = ""
                                if arr.count == 1 {
                                    append += " "+arr[0]
                                }else if arr.count == 2 {
                                    append += " " + arr[0] + ", " + arr[1]
                                }else {
                                    append += " " + arr[0] + ", " + arr[1] + " +\(arr.count - 2) more"
                                }
                                paymentTitle.text = String(format: Paid, requestedString, append)
                            }else {
                                paymentTitle.text = String(format: Paid, requestedString, (nsmutable!["paymentHeader"] as? String)!)
                            }
                        }
                        handlePaymentActionbuttonVisibality(isHidden: true)
                        
                    }else if(viewModel.contactId != nil){
                        paymentTitle.text = String(format: Paid, viewModel.displayName!, You)
                        handlePaymentActionbuttonVisibality(isHidden: true)
                    }
                    paymentMoney.text = amountString
//                    paymentResponseButtons.isHidden = true
                }
                
                if nsmutable!["paymentReceiver"] != nil, let paymentReceiver = nsmutable!["paymentReceiver"] as? String {
                    if paymentReceiver.caseInsensitiveCompare(ALUserDefaultsHandler.getUserId()) != ComparisonResult.orderedSame  && paymentReceiver.caseInsensitiveCompare(viewModel.contactId ?? "") != ComparisonResult.orderedSame{
                        showRightImageView(paymentReceiver: paymentReceiver)
                    }
                }else {
                    if let usersRequested = nsmutable?["usersRequested"] as? String{
                        let replacedString =   usersRequested.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]",with: "").replacingOccurrences(of: "\"",with: "")
                        let usersArray : [String] = replacedString.components(separatedBy: ",")
                        if !usersArray.contains(ALUserDefaultsHandler.getUserId()){
                            var otherUser: String
                            for user in usersArray {
                                if user.caseInsensitiveCompare(ALUserDefaultsHandler.getUserId()) != ComparisonResult.orderedSame && user.caseInsensitiveCompare(viewModel.contactId ?? "") != ComparisonResult.orderedSame {
                                    otherUser = user
                                    showRightImageView(paymentReceiver: otherUser)
                                }
                            }
                        }else {
                            rightImageView.isHidden = true
                        }
                    }else {
                     rightImageView.isHidden = true
                    }
                }
            }
            
            paymentSubjctTitle.text = Asunto
            paymentSubjctText.text = paymentSubject as? String
            
            setUpPaymentMessageColor(paymentStatus: paymentStatus as! String)
        }
        timeLabel.text   = viewModel.time
    }
    
    func showRightImageView(paymentReceiver: String){
        rightImageView.isHidden = false
        
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        let contact = ALContactService.init().loadContact(byKey: "userId", value: paymentReceiver)
        
        if let url = contact?.friendDisplayImgURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.rightImageView.kf.setImage(with: resource, placeholder: placeHolder, options: nil, progressBlock: nil, completionHandler: nil)
        } else {
            self.rightImageView.image = placeHolder
        }
    }
    
    private func setUpPaymentMessageColor(paymentStatus: String){
        var paymentColor = ALKConfiguration.init().customPrimary;//default
        switch (paymentStatus){
            case "paymentSent":
                paymentColor = ALKConfiguration.init().customPrimary
            case "paymentRequested":
                paymentColor = ALKConfiguration.init().paymentRequested
            case "paymentRejected":
                paymentSubjctTitle.text = Re
                paymentColor = ALKConfiguration.init().paymentRequested
            case "paymentAccepted":
                paymentColor = ALKConfiguration.init().customPrimary
            case "paymentReceived":
                paymentColor = ALKConfiguration.init().paymentReceived
            default:
                print("This should never occur");
        }
        paymentTitle.textColor = UIColor.white
        paymentTitle.backgroundColor = paymentColor
        paymentMoney.textColor = paymentColor
        paymentSubjctTitle.textColor = paymentColor
        bubbleView.layer.borderColor = paymentColor.cgColor
        bubbleView.layer.borderWidth = 2
        bubbleView.layer.cornerRadius = 12
        bubbleView.clipsToBounds = true
        if paymentStatus == "paymentRejected" {
            paymentMoney.textColor = ALKConfiguration.init().strikeThroughTextColor
        }
        if paymentStatus == "paymentAccepted" {
            paymentMoney.textColor = ALKConfiguration.init().customPrimaryDark
        }
    }
    
    func handlePaymentActionbuttonVisibality(isHidden: Bool) {
        paymentRejectButton.isHidden = isHidden
        paymentAceptButton.isHidden = isHidden
        paymentResponseButtons.isHidden = isHidden
    }
    
    func actionTapped(button: UIButton) {
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.mediaViewer, bundle: Bundle.applozic)
        
        let nav = storyboard.instantiateInitialViewController() as? UINavigationController
        let vc = nav?.viewControllers.first as? ALKMediaViewerViewController
        let dbService = ALMessageDBService()
        guard let messages = dbService.getAllMessagesWithAttachment(forContact: viewModel?.contactId, andChannelKey: viewModel?.channelKey, onlyDownloadedAttachments: true) as? [ALMessage] else { return }
        
        let messageModels = messages.map { $0.messageModel }
        NSLog("Messages with attachment: ", messages )
        
        guard let viewModel = viewModel as? ALKMessageModel,
            let currentIndex = messageModels.index(of: viewModel) else { return }
        vc?.viewModel = ALKMediaViewerViewModel(messages: messageModels, currentIndex: currentIndex)
        
        UIViewController.topViewController()?.present(nav!, animated: true, completion: {
            button.isEnabled = true
        })
    }
    
    func actionAccept(button: UIButton) {
//        if(viewModel?.channelKey != nil){
//            let channelService = ALChannelDBService()
//            if(channelService.isChannelLeft(viewModel?.channelKey)){
//                print("User is not in group !")
//            }else{
//                processPaymentAccept()
//            }
//        }else{
//            processPaymentAccept()
//
//        }
        
        
//        paymentAction()
    }
    
    func paymentAction(_ button: UIButton) {
        paymentResponseButtons.isHidden = true
        if let channelKey = viewModel?.channelKey, ALChannelDBService().isChannelLeft(channelKey) {
            print("User is not in the group !")
            return
        }
        let model  =  ALKPaymentModel();
        model.parentMessageKey = viewModel?.identifier
        model.launchPaymentPage = true
        model.groupId = viewModel?.channelKey
        model.userId = viewModel?.contactId
        
        switch button {
            case paymentRejectButton:
                model.paymentType = "paymentRejected"
            case paymentAceptButton:
                model.paymentType = "paymentAccepted"
            default:
                print("NOT POSIIBBLLE Still do nothing")
        }
        
        if let nsmutable = viewModel?.metadata {
            if let parentMessageKey = nsmutable["parentMessageKey"] as? String {
                model.parentMessageKey = parentMessageKey
            }
            if let paymentAmount = nsmutable["amount"] as? String {
                model.paymentAmount = paymentAmount
            }
            if let paymentSubject = nsmutable["paymentSubject"] as? String {
                model.paymentSubject = paymentSubject
            }
        }
        
        let dict = ["paymentMessage": model.toString()]
        BroadcastToIonic.sendBroadcast(name: "paymentCallback", data: dict)
        self.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    func processPaymentAccept(){
        let viewController:ALKAmountPayController   = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ALKAmountPayController") as UIViewController as! ALKAmountPayController
        let model  =  ALKPaymentModel();
        
        model.userId =  viewModel?.contactId
        model.messageKey =   viewModel?.identifier
        model.groupId =   viewModel?.channelKey
        viewController.paymentModleData = model
        
        UIViewController.topViewController()?.present(viewController, animated: true, completion: {
        })
        
    }
    
    func actionReject(button: UIButton) {
        paymentRejectButton.isHidden = true
        paymentAceptButton.isHidden = true
        if(viewModel?.channelKey != nil){
            let channelService = ALChannelDBService()
            if(channelService.isChannelLeft(viewModel?.channelKey)){
                print("User is not in group !")
            }else{
                processPaymentReject()
            }
            
        }else{
            processPaymentReject()
            
        }
        
    }
    
    
    func processPaymentReject(){
        var dictionaryMetadata = Dictionary<String, Any>();
        dictionaryMetadata =  (viewModel?.metadata)!
        let messageService = ALMessageService();
        let messagedb = ALMessageDBService();
        
        if( viewModel?.identifier != nil){
            let message = messagedb.getMessage("key", value:viewModel?.identifier);
            dictionaryMetadata["hiddenStatus"] = "false"
            let paymentId =  dictionaryMetadata["paymentId"]
            let  paymentMessage = dictionaryMetadata["paymentMessage"]
            let  paymentSubject = dictionaryMetadata["paymentSubject"]
            let  paymentStatus = dictionaryMetadata["paymentStatus"]
            let   richMessageType = dictionaryMetadata["richMessageType"]
            let   usersRequested = dictionaryMetadata["usersRequested"]
            
            if(dictionaryMetadata["paymentHeader"]  != nil){
                dictionaryMetadata.removeValue(forKey: "paymentHeader")
            }
            
            if(usersRequested == nil ){
                dictionaryMetadata["paymentStatus"] = "paymentRejected"
            }else{
                dictionaryMetadata[ALUserDefaultsHandler.getUserId()]  = "done"
            }
            
            if(message?.channelKey != nil){
                dictionaryMetadata["paymentReceiver"] = message?.to
            }
            messageService.updateMessageMetaData(viewModel?.identifier, withMessageMetaData: NSMutableDictionary(dictionary: dictionaryMetadata),withCompletionHandler:{
                apirespone, error in
                if((error == nil) ){
                    
                    let dbMessage = messagedb.getMessage("key", value:message?.key)
                    var nsmutableMeatdata = NSMutableDictionary();
                    nsmutableMeatdata =   (dbMessage?.metadata)!
                    let   usersRequestedArray = nsmutableMeatdata["usersRequested"]
                    if(nsmutableMeatdata["paymentStatus"] != nil &&  nsmutableMeatdata["paymentStatus"] as! String == "paymentRequested" && usersRequestedArray != nil){
                        
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
                        message.contentType = Int16(ALMESSAGE_RICH_MESSAGING)
                        message.type = "5"
                        message.source = Int16(SOURCE_IOS)
                        
                        nsmutableMeatdata["paymentId"] =  nsmutableMeatdata["paymentId"]
                        
                        nsmutableMeatdata["hiddenStatus"] = "false"
                        nsmutableMeatdata["paymentStatus"] = "paymentRejected"
                        nsmutableMeatdata["richMessageType"] = "paymentMessage"
                        nsmutableMeatdata["paymentReceiver"] = dbMessage?.to;
                        message.metadata = nsmutableMeatdata
                        ALMessageService.sendMessages(message, withCompletion: {
                            message, error in
                            if(message != nil){
                            }
                            self.delegate?.messageUpdated()
                            
                        })
                        
                    }
                    
                }
            })
            
        }
    }
    
    override func setupStyle() {
        super.setupStyle()
        
        timeLabel.setStyle(style: ALKMessageStyle.time)
    }
    
    override func setupViews() {
        super.setupViews()
        
        paymentRejectButton.isHidden = true;
        paymentAceptButton.isHidden = true;
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        paymentAceptButton.isUserInteractionEnabled = true
        paymentTitle.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(titleClick))
        paymentTitle.addGestureRecognizer(tapGesture)
        
        paymentRejectButton.addTarget(self, action: #selector(paymentAction(_:)), for: .touchUpInside)
        paymentAceptButton.addTarget(self, action: #selector(paymentAction(_:)), for: .touchUpInside)
        
        paymentRejectButton.isUserInteractionEnabled = true
        
        contentView.addViewsForAutolayout(views: [avatarImageView,nameLabel,bubbleView,timeLabel, rightImageView])
        bubbleView.addViewsForAutolayout(views: [paymentTitle,paymentMoney,paymentSubjctTitle,paymentSubjctText,paymentResponseButtons])
        bubbleView.bringSubview(toFront:paymentTitle)
        bubbleView.bringSubview(toFront:paymentMoney)
        bubbleView.bringSubview(toFront:paymentSubjctTitle)
        bubbleView.bringSubview(toFront:paymentSubjctText)
        bubbleView.bringSubview(toFront: paymentResponseButtons)
        contentView.bringSubview(toFront:nameLabel)
        
        nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 10).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -10).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: bubbleView.topAnchor, constant: -2).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18).isActive = true
        avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: 0).isActive = true
        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 9).isActive = true
        avatarImageView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -10).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 37).isActive = true
        avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor).isActive = true
        
        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15).isActive = true
        //bubbleView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
//        let width = UIScreen.main.bounds.width * 0.10
//        bubbleView.widthAnchor.constraint(equalToConstant: width)//Not working dont know why
        bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant:10).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -10).isActive = true
        
        timeLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 70).isActive = true
        timeLabel.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -23).isActive  = true
        
        paymentTitle.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        paymentTitle.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        paymentTitle.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
//        paymentTitle.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        paymentMoney.topAnchor.constraint(equalTo: paymentTitle.bottomAnchor, constant: 10).isActive = true
        paymentMoney.leadingAnchor.constraint(equalTo: paymentTitle.leadingAnchor).isActive = true
        paymentMoney.trailingAnchor.constraint(equalTo: paymentTitle.trailingAnchor).isActive = true
//        paymentMoney.bottomAnchor.constraint(equalTo: paymentTitle.bottomAnchor, constant: 30).isActive = true
        paymentMoney.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        paymentSubjctTitle.topAnchor.constraint(equalTo: paymentMoney.bottomAnchor, constant: 10).isActive = true
        paymentSubjctTitle.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 5).isActive = true
        paymentSubjctTitle.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        paymentSubjctText.topAnchor.constraint(equalTo: paymentMoney.bottomAnchor, constant: 10).isActive = true
        paymentSubjctText.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -5).isActive = true
        paymentSubjctText.leadingAnchor.constraint(equalTo: paymentSubjctTitle.trailingAnchor, constant: 10).isActive = true
        
//        paymentResponseButtons.topAnchor.constraint(equalTo: paymentSubjctTitle.bottomAnchor, constant: 1).isActive = true
        paymentResponseButtons.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        paymentResponseButtons.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        paymentResponseButtons.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        paymentResponseButtons.addBackground(color: ALKConfiguration.init().paymentRequested)
        
        //right imageView
        rightImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18).isActive = true
        rightImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: 0).isActive = true
        rightImageView.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 9).isActive = true
//        rightImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        rightImageView.heightAnchor.constraint(equalToConstant: 37).isActive = true
        rightImageView.widthAnchor.constraint(equalTo: rightImageView.heightAnchor).isActive = true
    }
    
    @objc private func uploadButtonAction(_ selector: UIButton) {
        uploadTapped?(true)
    }
    
    
    
    deinit {
        actionButton.removeTarget(self, action: #selector(actionTapped), for: .touchUpInside)
    }
    
    
    
    func updateView(for state: state) {
        DispatchQueue.main.async {
            self.updateView(state: state)
        }
    }
    
    func titleClick(){
        
        if(viewModel?.channelKey != nil){
            
            let storyboard = UIStoryboard(name: "ALKPaymentUsers", bundle:Bundle.applozic )
            
            
            if let vc = storyboard.instantiateViewController(withIdentifier: "PaymentUsers") as? ALKBaseNavigationViewController {
                
                guard let firstVC = vc.viewControllers.first else {return}
                
                var  viewController = firstVC as! ALPaymentUsersController
                
                
                var nsmutableMeatdata = Dictionary<String, Any>();
                nsmutableMeatdata =   (viewModel?.metadata)!
                
                let ns = nsmutableMeatdata["usersRequested"] as? String;
                if(ns != nil){
                    let string1 =   ns?.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]",with: "").replacingOccurrences(of: "\"",with: "")
                    let arary : [String] = string1!.components(separatedBy: ",")
                    viewController.groupMembers = arary as! [String]
                    UIViewController.topViewController()?.present(vc, animated: true, completion: {
                        
                    })
                    
                }
            }
            
        }
        
    }
    
    private func updateView(state: state) {
        
    }
    
    func setImage(imageView: UIImageView, name: String) {
        DispatchQueue.global(qos: .background).async {
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(name)
            do {
                let data = try Data(contentsOf: path)
                DispatchQueue.main.async {
                    imageView.image = UIImage(data: data)
                }
            } catch {
                DispatchQueue.main.async {
                    imageView.image = nil
                }
            }
        }
    }
    
    @objc private func acceptButtonButtonAction(_ selector: UIButton) {
        accpetButtonTapped?(true)
    }
    
    fileprivate func updateDbMessageWith(key: String, value: String, filePath: String) {
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        let dbMessage: DB_Message = messageService.getMessageByKey(key, value: value) as! DB_Message
        dbMessage.filePath = filePath
        do {
            try alHandler?.managedObjectContext.save()
        } catch {
            NSLog("Not saved due to error")
        }
    }
    
    
}
