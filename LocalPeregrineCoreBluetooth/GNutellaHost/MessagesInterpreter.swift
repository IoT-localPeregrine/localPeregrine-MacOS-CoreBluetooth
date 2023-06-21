import Foundation
import CoreBluetooth

protocol MessagesInterpretable {
    func subscribeToMessages(of type: MessageType, subscription: @escaping (NSData)->Void)
    func send(message: Message, from sender: UUID)
}

class MessagesInterpreter: NSObject, MessagesInterpretable {
    
    public init(dataDistributor: DataDistributor) {
        self.dataDistributor = dataDistributor
    }
    
    private let dataDistributor: DataDistributor
    private var connections = Dictionary<UUID,L2CapConnection>()
    private var subscriptions = Dictionary<MessageType, (NSData)->Void>()
    private var messagesPassed = Dictionary<UInt64, UUID>()
    private var messagesSent = Set<UInt64>()
    private var lastMessageId: UInt64 = 0
    
    func subscribeToMessages(of type: MessageType, subscription: @escaping (NSData) -> Void) {
        subscriptions[type] = subscription
    }
    
    func handleIncomingMesage(message: Message) {
        guard message.ttl > 0,
              ( (message.type == .ping || message.type == .query) // due to gnutella protocol:
                ^ messagesPassed.keys.contains(message.id) )      // ping&pong + query&queryHit have the same id
                || messagesSent.contains(message.id),
              let messageData = message.asData() as? Data else { return }
        
        if lastMessageId < message.id { lastMessageId = message.id }
        
        switch message.type {
        case .ping, .query:
            messagesPassed[message.id] = message.sender.address
            subscriptions[message.type]?(message.data as NSData)
            if !messagesSent.contains(message.id) {
                send(message: message, to: nil, from: message.sender.address)
            }
        case .pong, .queryHit:
            if messagesSent.contains(message.id) {
                subscriptions[message.type]?(message.data as NSData)
            } else {
                send(message: message, to: messagesPassed[message.id], from: message.sender.address)
            }
        case .push:
            // хз
            return
        }
    }
    
    public func send(message: Message, from sender: UUID) {
        messagesSent.insert(message.id)
        send(message: message, to: nil, from: sender)
    }
    
    private func send(message: Message, to receiver: UUID?, from sender: UUID) {
        if let receiver = receiver,
           receiver != sender,
           let connection = connections[receiver]
        {
            var newMessage = message
            newMessage.id = lastMessageId + 1
            connection.send(data: newMessage.data)
        } else {
            connections
                .filter({ $0.key != sender })
                .values
                .forEach { $0.send(data: message.data) }
        }
        
    }
}

extension MessagesInterpreter: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Service discovery error - \(error)")
            return
        }
    
        for service in peripheral.services ?? [] {
            if service.uuid == Constants.localPeregrineServiceID {
                peripheral.discoverCharacteristics([Constants.messsageUuid], for: service)
            }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error = error {
            print("Characteristic discovery error - \(error)")
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            print("Discovered characteristic \(characteristic)")
            if characteristic.uuid ==  Constants.messsageUuid {
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error = error {
            print("Characteristic update error - \(error)")
            return
        }
        
        if let dataValue = characteristic.value,
           var message = Message(from: dataValue as NSData) {
            message.sender = LPBluetoothAddress(address: peripheral.identifier)
            handleIncomingMesage(message: message)
        } else {
            print("Problem decoding message")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        if let error = error {
            print("Error opening l2cap channel - \(error.localizedDescription)")
            return
        }
        guard let channel = channel else {
            return
        }
        connections[peripheral.identifier] = L2CapPeripheralConnection(channel: channel)
    }
}
