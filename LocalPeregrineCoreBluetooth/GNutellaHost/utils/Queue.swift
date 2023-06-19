import Foundation

internal struct Queue<T> {
    var queue: [T]
    
    init() {
        self.queue = []
    }
    
    mutating public func add(element: T) {
        queue.append(element)
    }
    
    mutating public func pop() -> T? {
        guard !queue.isEmpty else {
            return nil
        }
        return queue.removeFirst()
    }
}

extension Queue: Sequence, IteratorProtocol {
    typealias Element = T
    
    mutating func next() -> Element? {
        pop()
    }
}
