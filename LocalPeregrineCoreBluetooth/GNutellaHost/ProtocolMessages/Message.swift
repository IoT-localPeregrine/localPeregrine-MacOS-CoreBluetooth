internal struct Message {
    let sender: LPBluetoothAddress
    let receiver: LPBluetoothAddress
    let type: MessageType
    let data: Data
}

extension Message {
    init?(from messageData: NSData) {
        guard let coding = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: MessageCoding.self,
            from: messageData as Data
        ) else {
            return nil
        }
        type = coding.type
        data = coding.data
        sender = coding.sender
        receiver = coding.receiver
    }
    
    func asData() -> NSData? {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: MessageCoding(self),
            requiringSecureCoding: true
        ) as NSData else {
            return nil
        }
        return data
    }

    @objc(MessageCoding)class MessageCoding: NSObject, NSCoding {
        let sender: LPBluetoothAddress
        let receiver: LPBluetoothAddress
        let type: MessageType
        let data: Data

        init(_ myStruct: Message) {
            sender = myStruct.sender
            receiver = myStruct.receiver
            type = myStruct.type
            data = myStruct.data
        }

        required init?(coder aDecoder: NSCoder) {
            type = aDecoder.decodeObject(forKey: "type") as! MessageType
            data = aDecoder.decodeObject(forKey: "data") as! Data
            sender = aDecoder.decodeObject(forKey: "sender") as! LPBluetoothAddress
            receiver = aDecoder.decodeObject(forKey: "receiver") as! LPBluetoothAddress
        }

        func encode(with coder: NSCoder) {
            coder.encode(sender, forKey: "sender")
            coder.encode(receiver, forKey: "receiver")
            coder.encode(type, forKey: "type")
            coder.encode(data, forKey: "data")
        }
    }
}
