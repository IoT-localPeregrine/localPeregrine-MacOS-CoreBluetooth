import Foundation
import CoreBluetooth

public class GNutellaBluetoothHost: NSObject {
    private let central: L2CapCentralManager
    private let peripheralManager: L2CapPeripheralManager
    private let messenger: MessagesInterpreter
    
    private var connectedPeripherals = [CBPeripheral]()
    
    private var discoveredNetworkHandler: ((String) -> ())?
    private var discoveredNetworks = Dictionary<String, [CBPeripheral]>()
    
    override init() {
        central = L2CapCentralManager()
        peripheralManager = L2CapPeripheralManager()
        messenger = MessagesInterpreter()
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
    
    public func connect(networkName: String) -> Bool {
        central.stopScanning()
        
        guard let peripherals = discoveredNetworks[networkName] else {
            return false
        }
        discoveredNetworks.removeAll(keepingCapacity: false)
        
        peripherals.forEach( {$0.delegate = messenger} )
        return ( central.connect(peripherals: peripherals) == .success // blocking
                     && !connectedPeripherals.isEmpty )
    }
    
    public func disconnect(from peripheral: CBPeripheral) {
        central.disconnect(peripheral: peripheral)
    }
    
    public func send(data: Data, to receiver: UUID?, from sender: UUID) {
        messenger.send(data: data, to: receiver, from: sender)
    }
    
    func subscribeToIncomingMessages(type: MessageType, closure: @escaping((NSData) -> Void) ) {
        messenger.subscribeToMessages(of: type, subscription: closure)
    }
    
}

extension GNutellaBluetoothHost: L2CapCentralManagerDelegate {
    func haveDiscovered(peripheral: CBPeripheral, with advertisement: [String : Any], rssi: NSNumber) {
        // TODO: set advertisement info in peripheral
        guard let networkName = advertisement["name"] as? String else {
            return
        }
        discoveredNetworks[networkName, default: []].append(peripheral)
        discoveredNetworkHandler?(networkName)
    }
    
    func setConnectionResult(_ result: Result<CBPeripheral, Error>) {
        switch result {
        case .success(let peripheral):
            connectedPeripherals.append(peripheral)
            peripheral.discoverServices([Constants.localPeregrineServiceID])
        case .failure(_):
            return
            // TODO: прокидывать диме ошибку
        }
    }
    
    
}
