internal struct Message {
    let sender: LPBluetoothAddress
    let receiver: LPBluetoothAddress
    let type: MessageType
    let data: Data
    let ttl: UInt8
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
        ttl = coding.ttl
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
        let ttl: UInt8

        init(_ myStruct: Message) {
            sender = myStruct.sender
            receiver = myStruct.receiver
            type = myStruct.type
            data = myStruct.data
            ttl = myStruct.ttl
        }

        required init?(coder aDecoder: NSCoder) {
            type = aDecoder.decodeObject(forKey: "type") as! MessageType
            data = aDecoder.decodeObject(forKey: "data") as! Data
            sender = aDecoder.decodeObject(forKey: "sender") as! LPBluetoothAddress
            receiver = aDecoder.decodeObject(forKey: "receiver") as! LPBluetoothAddress
            ttl = (aDecoder.decodeObject(forKey: "ttl") as! UInt8) - 1
        }

        func encode(with coder: NSCoder) {
            coder.encode(sender, forKey: "sender")
            coder.encode(receiver, forKey: "receiver")
            coder.encode(type, forKey: "type")
            coder.encode(data, forKey: "data")
            coder.encode(ttl, forKey: "ttl")
        }
    }
}
