import Foundation
import CoreBluetooth

public class GNutellaBluetoothHost: NSObject {
    private let central: L2CapCentralManager
    private let peripheralManager: L2CapPeripheralManager
    private let interpreter: MessagesInterpreter
    
    private var connectedPeripherals = [CBPeripheral]()
    
    private var discoveredNetworkHandler: ((String) -> ())?
    
    override init() {
        central = L2CapCentralManager()
        peripheralManager = L2CapPeripheralManager()
        interpreter = MessagesInterpreter()
        super.init()
        
        central.delegate = self
        
        peripheralManager.connectionHandler = { [weak self] uuid, connection in
            guard let self = self else { return }
//            self.connections[uuid] = connection
        }
    }
    
    public func explore(handler: @escaping(String) -> ()) {
        // включаем central
        central.startScanning()
        discoveredNetworkHandler = handler
        // читаем имя сети + ИД узла с перифералов
        // передаю что имеется диме
    }
    
    public func connect(peripherals: [CBPeripheral]) -> Bool {
        central.stopScanning()
        peripherals.forEach( {$0.delegate = interpreter} )
        return ( central.connect(peripherals: peripherals) == .success // blocking
                     && !connectedPeripherals.isEmpty )
    }
    
    public func disconnect(from peripheral: CBPeripheral) {
        central.disconnect(peripheral: peripheral)
    }
    
    public func send(data: Data, to receiver: UUID) {
        guard let connection = connections[receiver] else {
            let peripherals = connectedPeripherals.first(where: {$0.identifier == receiver} )
            connect(peripherals: [])
            return
        }
        connection.send(data: data)
    }
    
    func subscribeToIncomingMessages(type: MessageType, closure: @escaping((NSData) -> Void) ) {
        interpreter.subscribeToMessages(of: type, subscription: closure)
    }
    
}

extension GNutellaBluetoothHost: L2CapCentralManagerDelegate {
    func haveDiscovered(peripheral: CBPeripheral, with advertisement: [String : Any], rssi: NSNumber) {
        // TODO: set advertisement info in peripheral
        guard let networkName = advertisement["name"] as? String else {
            return
        }
        
        discoveredNetworkHandler?(networkName)
    }
    
    func setConnectionResult(_ result: Result<CBPeripheral, Error>) {
        switch result {
        case .success(let peripheral):
            connectedPeripherals.append(peripheral)
            connections[peripheral.identifier] = L2CapCentralConnection(peripheral: peripheral)
            // TODO: удалять соединения при отключении периферала
            peripheral.discoverServices([Constants.localPeregrineServiceID])
        case .failure(let error):
            return
            // TODO: прокидывать диме ошибку
        }
    }
    
    
}
