import Foundation
import CoreBluetooth
/**
 L2Cap Central Object. Starts scanning as soon as bluetooth module is on. To
 */

protocol L2CapCentralManagerDelegate {
    func haveDiscovered(peripheral: CBPeripheral, with advertisement: [String : Any], rssi: NSNumber)
    func setConnectionResult(_ result: Result<CBPeripheral, Error>)
    func informationUpdate(_ message: Message)
}

class L2CapCentralManager: NSObject {
    public var delegate: L2CapCentralManagerDelegate?
    
    private var central: CBCentralManager!
    private let centralQueue = DispatchQueue(label: "centralQueue")
    
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
    
    public func connect(peripheral: CBPeripheral, connectionHandler:  @escaping L2CapConnectionCallback)  {
        central.connect(peripheral)
        let l2Connection = L2CapCentralConnection(peripheral: peripheral, connectionCallback: connectionHandler)
        connections[peripheral.identifier] = l2Connection
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
        delegate?.setConnectionResult(.success(peripheral))
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
                    failedConnections.removeValue(forKey: peripheral.identifier)
                }
            }
        }
        // TODO: сделать нормально проверку подключений/фейлов
    }
}

extension L2CapCentralManager: CBPeripheralDelegate {
    
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
            delegate?.informationUpdate(message)
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
        self.channel = channel
        channel.inputStream.delegate = self
        channel.outputStream.delegate = self
        channel.inputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.outputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.open()
        connectionHandler(peripheral.identifier, self)
    }
}



