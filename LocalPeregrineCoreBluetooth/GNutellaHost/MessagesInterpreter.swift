import Foundation
import CoreBluetooth

protocol MessagesInterpretable {
    func subscribeToMessages(of type: MessageType, subscription: @escaping (NSData)->Void)
}

internal class MessagesInterpreter: NSObject, MessagesInterpretable {
    
    private var connections = Dictionary<UUID,L2CapConnection>()
    private var subscriptions = Dictionary<MessageType, (NSData)->Void>()
    
    func subscribeToMessages(of type: MessageType, subscription: @escaping (NSData) -> Void) {
        subscriptions[type] = subscription
    }
    
    func handleIncomingMesage(message: Message) {
        guard !message.data.isEmpty else { return }
        switch message.type {
        case .ping:
            // pass ping to all connected centrals
            return
        case .pong:
            // search for peripheral from where ping was got
            return
        case .query:
            // pass message to Дима & to all connected periferals
            return
        case .queryHit:
            // search for peripheral from where query was got
            return
        case .push:
            // хз
            return
        }
    }
    
    public func send(data: Data, to receiver: UUID?) {
        if let receiver = receiver,
           let connection = connections[receiver] {
            connection.send(data: data)
        } else {
            connections.values.forEach { $0.send(data: data) }
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
           let message = Message(from: dataValue as NSData) {
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
