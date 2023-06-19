import Foundation

enum LPAddressType {
    case bluetooth
    case tcpIp
}

protocol LPAddress: Equatable {
    func serialize() -> String
    func getType() -> LPAddressType
}

struct LPBluetoothAddress: LPAddress {
    let address: UUID
    
    func getType() -> LPAddressType {
        return .bluetooth
    }
    
    func serialize() -> String {
        return address.uuidString
    }
}

struct LPTCPAddress: LPAddress {
    let address: UUID // TODO: узнать конкретно в каком виде передается TCP/IP адрес
    
    func serialize() -> String {
        address.uuidString
    }
    
    func getType() -> LPAddressType {
        .tcpIp
    }
}
