import Foundation
import CoreBluetooth

public class GNutellaBluetoothHost: NSObject {
    private let central: L2CapCentralManager
    private let peripheralManager: L2CapPeripheralManager
    private let interpreter: MessagesInterpretable
    
    private var connections = Dictionary<UUID,L2CapConnection>()
    private var discoveredPeripherals = [CBPeripheral]()
    
    private var discoveredNetworkHandler: ((String) -> ())?
    
    override init() {
        central = L2CapCentralManager()
        peripheralManager = L2CapPeripheralManager()
        interpreter = MessagesInterpreter()
        super.init()
        
        central.delegate = self
        
        peripheralManager.connectionHandler = { [weak self] uuid, connection in
            guard let self = self else { return }
            self.connections[uuid] = connection
        }
    }
    
    public func explore(handler: @escaping(String) -> ()) {
        // включаем central
        central.startScanning()
        discoveredNetworkHandler = handler
        // читаем имя сети + ИД узла с перифералов
        // передаю что имеется диме
        
        
//        peripherals.forEach({[weak self] peripheral in
//            guard let self = self else { return }
//            self.central.connect(peripheral: peripheral) { [weak self] uuid, connection in
//                guard let self = self else { return }
//                self.connections[uuid] = connection
//            }
//        })
    }
    
    public func connect(peripherals: [CBPeripheral]) -> Bool {
        central.stopScanning()
        guard discoveredPeripherals.contains(peripherals) else {
            // TODO: придумать как выкинуть ошибку
            return false
        }
        peripherals.forEach({ [weak self] peripheral in
            self?.central.connect(
                peripheral: peripheral,
                connectionHandler: self!.connectionCallback
            )
        })
    }
    
    public func disconnect(from peripheral: CBPeripheral) {
        central.disconnect(peripheral: peripheral)
    }
    
    public func send(data: Data, to receiver: UUID) {
        guard let connection = connections[receiver] else {
            let peripherals = discoveredPeripherals.first(where: {$0.identifier == receiver} )
            connect(peripherals: [])
            return
        }
        connection.send(data: data)
    }
    
    public func subscribeToIncomingMessages( closure: @escaping((NSData) -> Void) ) {
        newMessagesHandler = { [weak self] data in
            guard let message = Message(from: data),
                  let self = self else { return }
            self.interpreter.handleIncomingMesage(message: message)
            closure(data)
        }
    }
    
    private func connectionCallback(peripheral: UUID, connection: L2CapConnection) {
        discoveredPeripherals
            .filter( {pendingSendings.keys.contains($0.identifier)} )
            .forEach( { peripheral in
                send(data: pendingSendings[peripheral.identifier]!, to: peripheral.identifier)
            })
    }
}

extension GNutellaBluetoothHost: L2CapCentralManagerDelegate {
    func informationUpdate(_ message: Message) {
        interpreter.handleIncomingMesage(message: message)
    }
    
    func haveDiscovered(peripheral: CBPeripheral, with advertisement: [String : Any], rssi: NSNumber) {
        guard let networkName = advertisement["name"] as? String else {
            return
        }
        
        discoveredPeripherals.append(peripheral)
        discoveredNetworkHandler?(networkName)
        peripheral.discoverServices([Constants.localPeregrineServiceID])
    }
    
    func setConnectionResult(_ result: Result<CBPeripheral, Error>) {
        switch result {
        case .success(let success):
            <#code#>
        case .failure(let failure):
            <#code#>
        }
    }
    
    
}
