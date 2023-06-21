import Foundation
import CoreBluetooth

protocol MessagesInterpretable {
    func subscribeToMessages(of type: MessageType, subscription: @escaping (NSData)->Void)
    func send(data: Data, to receiver: UUID?, from sender: UUID)
}

class MessagesInterpreter: NSObject, MessagesInterpretable {
    
    public init(dataDistributor: DataDistributor) {
        self.dataDistributor = dataDistributor
    }
    
    private let dataDistributor: DataDistributor
    private var connections = Dictionary<UUID,L2CapConnection>()
    private var subscriptions = Dictionary<MessageType, (NSData)->Void>()
    private var messagesPassed = Dictionary<UInt64, UUID>()
    private var messagesSent = Dictionary<UInt64, Bool>()
    private var lastMessageId: UInt64 = 0
    
    func subscribeToMessages(of type: MessageType, subscription: @escaping (NSData) -> Void) {
        subscriptions[type] = subscription
    }
    
    func handleIncomingMesage(message: Message) {
        guard message.ttl > 0,
              ( (message.type == .ping || message.type == .query)
                ^ messagesPassed.keys.contains(message.id) ) || messagesSent.keys.contains(message.id),
              let messageData = message.asData() as? Data else { return }
        
        if lastMessageId < message.id { lastMessageId = message.id }
        
        switch message.type {
        case .ping:
            messagesPassed[message.id] = message.sender.address
            subscriptions[.ping]?(message.data as NSData)
            send(data: messageData, to: nil, from: message.sender.address)
        case .pong:
            subscriptions[.pong]?(message.data as NSData)
        case .query:
            subscriptions[.query]?(message.data as NSData)
            send(data: messageData, to: nil, from: message.sender.address)
        case .queryHit:
            subscriptions[.queryHit]?(message.data as NSData)
        case .push:
            // хз
            return
        }
    }
    
    public func send(data: Data, to receiver: UUID?, from sender: UUID) {
        if let receiver = receiver,
           receiver != sender,
           let connection = connections[receiver] {
            connection.send(data: data)
        } else {
            connections
                .filter({ $0.key != sender })
                .values
                .forEach { $0.send(data: data) }
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
