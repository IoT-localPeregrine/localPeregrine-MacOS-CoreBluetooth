import Foundation

protocol MessagesInterpretable {
    func handleIncomingMesage(message: Message)
    func subscribeToMessages(of type: MessageType, subscription: @escaping (NSData)->Void)
}

protocol MessagesInterpretatorDelegate {
    func send(data: Data, to receiver: UUID)
}

internal class MessagesInterpreter: MessagesInterpretable {
    public var delegate: MessagesInterpretatorDelegate?
    
    private var pendingSendings = Dictionary<UUID, Queue<Data>>()
    private var subscriptions = Dictionary< MessageType, (NSData)->Void >()
    
    func subscribeToMessages(of type: MessageType, subscription: @escaping (NSData) -> Void) {
        subscriptions[type] = subscription
    }
    
    func handleIncomingMesage(message: Message) {
        switch message.type {
        case .ping:
            // pass ping to all connected centrals
            return
        case .pong:
            // search for peripheral from where ping was got
            return
        case .query:
            // pass message to Дима & to all connected periferals
            return
        case .queryHit:
            // search for peripheral from where query was got
            return
        case .push:
            // хз
            return
        }
    }
    
    private func sendQueuedMessages(for receiver: UUID) {
        guard let queuedMessages = pendingSendings[receiver] else {
            return
        }
        
        pendingSendings.removeValue(forKey: receiver)
        
        queuedMessages.forEach({ [weak self] data in
            self?.delegate?.send(data: data, to: receiver)
        })
    }
}
