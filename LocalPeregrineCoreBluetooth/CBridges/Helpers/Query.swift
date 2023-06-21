import Foundation

extension QueryHit {
    init?(from queryHitData: NSData) {
        guard let coding = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: QueryHitCoding.self,
            from: queryHitData as Data
        ) else {
            return nil
        }
        self.init()
        files = coding.getList()
    }
    
    func asData() -> NSData? {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: QueryHitCoding(self),
            requiringSecureCoding: true
        ) as NSData else {
            return nil
        }
        return data
    }

    @objc(QueryHitCoding)class QueryHitCoding: NSObject, NSCoding {
        private var files: [ListNode_File]

        init(_ myStruct: QueryHit) {
            files = []
            super.init()
            files = listToArray(list: myStruct.files)
        }
        
        func listToArray(list: List_File) -> [ListNode_File] {
            var nodes: [ListNode_File] = []
            var currentNode = list.head.pointee
            var counter = list.count
            while counter > 0 {
                nodes.append(currentNode)
                currentNode = currentNode.next.move()
                counter -= 1
            }
            return nodes
        }
        
        func getList() -> List_File {
            return arrayToList(files)
        }
        
        private func arrayToList(_ anArray: [ListNode_File]) -> List_File {
            var array = anArray
            for i in 0..<array.count {
                let currentIndex = i
                let nextIndex = (i + 1) % array.count
                array[currentIndex].next = UnsafeMutablePointer<ListNode_File>.allocate(capacity: 1)
                array[currentIndex].next.initialize(to: array[nextIndex])
            }
            var headPointer = UnsafeMutablePointer<ListNode_File>.allocate(capacity: 1)
            headPointer.initialize(to: array.first!)
            var tailPointer = UnsafeMutablePointer<ListNode_File>.allocate(capacity: 1)
            tailPointer.initialize(to: array.last!)
            return List_File(head: headPointer, tail: tailPointer, count: array.count)
        }

        required init?(coder aDecoder: NSCoder) {
            files = aDecoder.decodeObject(forKey: "files") as! [ListNode_File]
        }

        func encode(with coder: NSCoder) {
            coder.encode(files, forKey: "files")
        }
    }
}

struct SwiftFile {
    let index: UInt32
    let size: UInt32
    let name: SString
}

struct SwiftListNode {
    let data: SwiftFile
    let next: UnsafeMutablePointer<SwiftListNode>
}
