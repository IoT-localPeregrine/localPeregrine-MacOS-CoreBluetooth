import Foundation
import CoreBluetooth

typealias L2CapDiscoveredPeripheralCallback = (CBPeripheral, [String : Any], NSNumber)->Void
typealias L2CapStateCallback = (CBManagerState)->Void
typealias L2CapConnectionCallback = (UUID, L2CapConnection)->Void
typealias L2CapDisconnectionCallback = (L2CapConnection,Error?)->Void
typealias L2CapReceiveDataCallback = (L2CapConnection,Data)->Void
typealias L2CapStateChangeCallback = (L2CapConnection,Stream.Event)->Void
typealias L2CapSentDataCallback = (L2CapConnection, Int)->Void

protocol L2CapConnection {
    
    var receiveCallback:L2CapReceiveDataCallback? {get set}
    var sentDataCallback: L2CapSentDataCallback? {get set}
    var stateChangeCallback: L2CapStateChangeCallback? { get set }
    
    func send(data: Data) -> Void
    func close() -> Void
}
