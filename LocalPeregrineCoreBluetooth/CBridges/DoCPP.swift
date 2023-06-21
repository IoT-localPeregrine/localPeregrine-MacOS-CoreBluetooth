//
//  SString.swift
//  LocalPeregrineCoreBluetooth
//
//  Created by Булат Мусин on 21.06.2023.
//

import Foundation


@_cdecl("inet_init")
public func inetInit() {}

@_cdecl("inet_exit")
public func inetExit() {}

@_cdecl("inet_connect_to_network")
public func connectToNetwork(_ networkName: SString) -> NetError {
    let result = CBridge.instance.host.connect(networkName: networkName.toString())
    return NetError(rawValue: result ? 0 : 1 )
}

@_cdecl("inet_explore_networks")
public func explore(_ closure: Wrapper_ExploreNetworkConsumerFunc) -> NetError {
    let swiftHandler: (String) -> () = { str in
        closure.func(str.toSString())
    }
    CBridge.instance.host.explore(handler: swiftHandler)
    return .init(0)
}

@_cdecl("inet_create")
public func createNetwork(_ name: SString) -> NetError {
    CBridge.instance.host.createNetwork(name: name.toString())
    return .init(0)
}

@_cdecl("inet_ping")
public func ping() -> NetError {
    CBridge.instance.host.sendMessage(type: .ping, data: Data())
    return .init(0)
}

@_cdecl("inet_query")
public func query(_ criteria: SString) -> NetError {
    guard let criteriaData = criteria.toString().data(using: .utf8) else {
        return .init(1)
    }
    CBridge.instance.host.sendMessage(type: .query, data: criteriaData)
    return .init(0)
}

@_cdecl("inet_subscribe_ping")
public func subscribePing(_ pingConsumer: Wrapper_PingConsumerFunc) -> NetError {
    CBridge.instance.host.subscribeToIncomingMessages(type: .ping) { _ in
        let peer = pingConsumer.func()
        guard let peerData = peer.asData()
        else {
            return
        }
        CBridge.instance.host.sendMessage(type: .pong, data: peerData as Data)
    }
    return .init(0)
}

@_cdecl("inet_subscribe_pong")
public func subscribePong(_ pongConsumer: Wrapper_PongConsumerFunc) -> NetError {
    CBridge.instance.host.subscribeToIncomingMessages(type: .pong) { data in
        guard let peer = Peer(from: data) else { return }
        pongConsumer.func(peer)
    }
    return .init(0)
}

@_cdecl("inet_subscribe_query")
public func subscribeQuery(_ queryConsumer: Wrapper_QueryConsumerFunc) -> NetError {
    CBridge.instance.host.subscribeToIncomingMessages(type: .pong) { data in
        guard let sstring = String(decoding: data, as: UTF8.self).toSString(),
              let queryData = queryConsumer.func(sstring).asData()
        else {
            return
        }
        CBridge.instance.host.sendMessage(type: .queryHit, data: queryData as Data)
    }
    return .init(0)
}

fileprivate final class CBridge {
    let host = GNutellaBluetoothHost()
    static let instance = CBridge()
}
