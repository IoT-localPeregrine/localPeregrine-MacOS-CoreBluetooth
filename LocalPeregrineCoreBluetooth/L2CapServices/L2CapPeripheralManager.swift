import CoreBluetooth

protocol DataDistributor {
    func startAdvertisingNetwork(name: String)
    func updateServiceValue(with message: Message)
}

class L2CapPeripheralManager: NSObject, DataDistributor {
    
    private var service: CBMutableService?
    private var characteristic: CBMutableCharacteristic?
    private var peripheralManager: CBPeripheralManager
    private var managerQueue = DispatchQueue.global(qos: .utility)
    private var connections: [UUID : L2CapConnection]?
    private var subscribedCentrals = Dictionary<CBMutableCharacteristic, [CBCentral]>()
    private var peripheralUUID: CBUUID?
    
    public override init() {
        peripheralManager = CBPeripheralManager(delegate: nil, queue: managerQueue)
        super.init()
        peripheralManager.delegate = self
    }
    
    public func startAdvertisingNetwork(name: String) {
        unpublishService()
        publishService()
        peripheralManager.startAdvertising(["name" : name])
    }
    
    public func updateServiceValue(with message: Message) {
        guard let characteristic = characteristic,
              let messageData = message.asData() as? Data else {
            return
        }
        peripheralManager.updateValue(
            messageData,
            for: characteristic,
            onSubscribedCentrals: self.subscribedCentrals[characteristic]
        )
    }
    
    private func unpublishService() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        characteristic = nil
        service = nil
    }
    
    // TODO: публиковать данные о сети
    private func publishService() {
        guard peripheralManager.state == .poweredOn else {
            unpublishService()
            return
        }
        
        service = CBMutableService(type: Constants.localPeregrineServiceID, primary: true)
        
        characteristic = CBMutableCharacteristic(
            type: Constants.messsageUuid,
            properties: [ CBCharacteristicProperties.read, CBCharacteristicProperties.indicate],
            value: nil,
            permissions: [CBAttributePermissions.readable]
        )
        
        service?.characteristics = [characteristic!]
        peripheralManager.add(service!)
    }
    
    // TODO: по идее надо будет сделать чтоб нам на централ пришла просьба о передаче информации, и тогда откроем канал
//    public func publishL2CAPChannel() {
//        peripheralManager.publishL2CAPChannel(withEncryption: false)
//    }
//
//    public func unpublishL2CAPChannel(channel: CBL2CAPChannel) {
//        connections?[channel.peer.identifier]?.close()
//        peripheralManager.unpublishL2CAPChannel(channel.psm)
//    }
}

extension L2CapPeripheralManager: CBPeripheralManagerDelegate {
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            peripheralUUID = periphe
        }
    }
    
    
    // TODO: все те же каналы
//    public func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
//        if let error = error {
//            print("Error publishing channel: \(error.localizedDescription)")
//            return
//        }
//        print("Published channel \(PSM)")
//    }
//
//    public func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
//        if let error = error {
//            print("Error opening channel: \(error.localizedDescription)")
//            return
//        }
//        if let channel = channel {
//            let connection = L2CapPeripheralConnection(channel: channel)
//            connections?[channel.peer.identifier] = connection
//            connectionHandler?(channel.peer.identifier, connection)
//        }
//    }
    
}
