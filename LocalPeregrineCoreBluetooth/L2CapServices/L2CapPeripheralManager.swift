import CoreBluetooth

class L2CapPeripheralManager: NSObject {
    
    private var service: CBMutableService?
    private var characteristic: CBMutableCharacteristic?
    private var peripheralManager: CBPeripheralManager
    private var managerQueue = DispatchQueue.global(qos: .utility)
    public var connectionHandler: L2CapConnectionCallback?
    private var connections: [UUID : L2CapConnection]?
    private var subscribedCentrals = Dictionary<CBMutableCharacteristic, [CBCentral]>()
    
    public override init() {
        peripheralManager = CBPeripheralManager(delegate: nil, queue: managerQueue)
        super.init()
        peripheralManager.delegate = self
    }
    
    // TODO: публиковать данные о сети
    public func publishService() {
        guard peripheralManager.state == .poweredOn else {
            unpublishService()
            return
        }
        service = CBMutableService(type: Constants.localPeregrineServiceID, primary: true)
        characteristic = CBMutableCharacteristic(type: Constants.messsageUuid, properties: [ CBCharacteristicProperties.read, CBCharacteristicProperties.indicate], value: nil, permissions: [CBAttributePermissions.readable] )
        service?.characteristics = [characteristic!]
        peripheralManager.add(service!)
       
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [Constants.localPeregrineServiceID]])
    }
    
    public func publishL2CAPChannel() {
        peripheralManager.publishL2CAPChannel(withEncryption: false)
    }
    
    public func unpublishL2CAPChannel(channel: CBL2CAPChannel) {
        connections?[channel.peer.identifier]?.close()
        peripheralManager.unpublishL2CAPChannel(channel.psm)
    }
    
    public func updateServiceValue(with data: Data, for characteristic: CBMutableCharacteristic) {
        peripheralManager.updateValue(data, for: characteristic, onSubscribedCentrals: self.subscribedCentrals[characteristic])
    }
    
    private func unpublishService() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        characteristic = nil
        service = nil
    }
}

extension L2CapPeripheralManager: CBPeripheralManagerDelegate {
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            publishService()
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        if let error = error {
            print("Error publishing channel: \(error.localizedDescription)")
            return
        }
        print("Published channel \(PSM)")
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        if let error = error {
            print("Error opening channel: \(error.localizedDescription)")
            return
        }
        if let channel = channel {
            let connection = L2CapPeripheralConnection(channel: channel)
            connections?[channel.peer.identifier] = connection
            connectionHandler?(channel.peer.identifier, connection)
        }
    }
    
}
