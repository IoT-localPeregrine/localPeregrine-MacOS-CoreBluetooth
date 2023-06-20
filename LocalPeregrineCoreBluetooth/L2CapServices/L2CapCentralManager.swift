import Foundation
import CoreBluetooth
/**
 L2Cap Central Object. Starts scanning as soon as bluetooth module is on. To
 */

protocol L2CapCentralManagerDelegate {
    func haveDiscovered(peripheral: CBPeripheral, with advertisement: [String : Any], rssi: NSNumber)
    func setConnectionResult(_ result: Result<CBPeripheral, Error>)
}

protocol L2CapcentralManagerMessagesDelegate {
    func informationUpdate(_ message: Message)
}

class L2CapCentralManager: NSObject {
    public var delegate: L2CapCentralManagerDelegate?
    public var messagesDelegate: L2CapcentralManagerMessagesDelegate?
    
    private var central: CBCentralManager!
    private let centralQueue = DispatchQueue(label: "centralQueue")
    private let connectionGroup = DispatchGroup()
    
    private var connections = Dictionary<UUID,L2CapConnection>()
    private var discoveredPeripherals = Set<UUID>()
    private var failedConnections = Dictionary<UUID,Int>()
    
    override public init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    public func startScanning() {
        guard central.state == .poweredOn else {
            return
        }
        central.scanForPeripherals(withServices: [Constants.localPeregrineServiceID], options: nil)
    }
    
    public func stopScanning() {
        central.stopScan()
    }
    
    public func connect(peripherals: [CBPeripheral]) -> DispatchTimeoutResult {
        peripherals.forEach({ peripheral in
            connectionGroup.enter()
            central.connect(peripheral)
        })
        return connectionGroup.wait(timeout: .now() + 30)
    }
    
    public func disconnect(peripheral: CBPeripheral) {
        guard discoveredPeripherals.contains(peripheral.identifier) else {
            return
        }
        central.cancelPeripheralConnection(peripheral)
    }
}

extension L2CapCentralManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    
    // TODO: возможно, стоит использовать rssi как метрику канала
    // Также возможно стоит в advertisementData добавить доступные каналы с peripheral (RIP у маршрутизатора)
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi: NSNumber
    ) {
        guard !discoveredPeripherals.contains(peripheral.identifier) else {
            return
        }
        discoveredPeripherals.insert(peripheral.identifier)
        delegate?.haveDiscovered(peripheral: peripheral, with: advertisementData, rssi: rssi)
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        connectionGroup.leave()
        delegate?.setConnectionResult(.success(peripheral))
        failedConnections.removeValue(forKey: peripheral.identifier)
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?)
    {
        if let error = error {
            switch failedConnections[peripheral.identifier] {
            case .none:
                failedConnections[peripheral.identifier] = 1
            case .some( let failCount ):
                failedConnections[peripheral.identifier]! += 1
                if failCount >= 2 {
                    delegate?.setConnectionResult(.failure(error))
                    central.cancelPeripheralConnection(peripheral)
                    connectionGroup.leave()
                    failedConnections.removeValue(forKey: peripheral.identifier)
                }
            }
        }
        // TODO: сделать нормально проверку подключений/фейлов
    }
}
