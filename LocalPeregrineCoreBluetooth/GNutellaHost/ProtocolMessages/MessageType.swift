internal enum MessageType: UInt8 {
    case ping       = 0x00
    case pong       = 0x01
    case query      = 0x80
    case queryHit   = 0x81
    case push       = 0x40
}
