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
        files = coding.files
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
        let files: [ListNode_File]

        init(_ myStruct: QueryHit) {
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
        
        func arrayToList(_ array: [ListNode_File]) -> List_File {
            array[0].
        }

        required init?(coder aDecoder: NSCoder) {
            files = aDecoder.decodeObject(forKey: "files") as! List_File
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
