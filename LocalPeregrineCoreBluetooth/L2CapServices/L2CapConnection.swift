import Foundation
import CoreBluetooth

class L2CapInternalConnection: NSObject, StreamDelegate, L2CapConnection {
    
    var channel: CBL2CAPChannel?
    
    public var receiveCallback:L2CapReceiveDataCallback?
    public var sentDataCallback: L2CapSentDataCallback?
    public var stateChangeCallback: L2CapStateChangeCallback?
    
    private var connectionQueue = DispatchQueue(label: "connectionQueue")
    
    private var outputData = Data()
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            print("Stream is open")
        case Stream.Event.endEncountered:
            print("End Encountered")
        case Stream.Event.hasBytesAvailable:
            print("Bytes are available")
            readBytes(from: aStream as! InputStream)
        case Stream.Event.hasSpaceAvailable:
            print("Space is available")
            send()
        case Stream.Event.errorOccurred:
            print("Stream error")
        default:
            print("Unknown stream event")
        }
        stateChangeCallback?(self,eventCode)
    }
    
    public func send(data: Data) -> Void {
        connectionQueue.sync  {
            outputData.append(data)
        }
        send()
    }
    
    private func send() {
        guard let ostream = channel?.outputStream, !outputData.isEmpty, ostream.hasSpaceAvailable else {
            return
        }
        let bytesWritten =  ostream.write(outputData)
        
        print("bytesWritten = \(bytesWritten)")
        sentDataCallback?(self,bytesWritten)
        connectionQueue.sync {
            if bytesWritten < outputData.count {
                outputData = outputData.advanced(by: bytesWritten)
                send()
            } else {
                outputData.removeAll()
            }
        }
    }
    
    public func close() {
        channel?.outputStream.close()
        channel?.inputStream.close()
        channel?.inputStream.remove(from: .main, forMode: .default)
        channel?.outputStream.remove(from: .main, forMode: .default)
        
        channel?.inputStream.delegate = nil
        channel?.outputStream.delegate = nil
        channel = nil
    }
    
    private func readBytes(from stream: InputStream) {
        let bufLength = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufLength)
        defer {
            buffer.deallocate()
        }
        let bytesRead = stream.read(buffer, maxLength: bufLength)
        var returnData = Data()
        returnData.append(buffer, count:bytesRead)
        receiveCallback?(self,returnData)
        if stream.hasBytesAvailable {
            readBytes(from: stream)
        }
    }
}

class L2CapCentralConnection: L2CapInternalConnection {
    
    internal init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
    }
    
    private var peripheral: CBPeripheral
    
    func discover() {
        peripheral.discoverServices([Constants.localPeregrineServiceID])
    }
}

class L2CapPeripheralConnection: L2CapInternalConnection {
    init(channel: CBL2CAPChannel) {
        super.init()
        self.channel = channel
        channel.inputStream.delegate = self
        channel.outputStream.delegate = self
        channel.inputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.outputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.open()
    }
}
