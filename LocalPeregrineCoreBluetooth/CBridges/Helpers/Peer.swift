import Foundation

extension Peer {
    init?(from peerData: NSData) {
        guard let coding = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: PeerCoding.self,
            from: peerData as Data
        ) else {
            return nil
        }
        self.init()
        id = coding.id
        number_of_files_shd = coding.filesShared
        number_of_kb_shd = coding.kbShared
    }
    
    func asData() -> NSData? {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: PeerCoding(self),
            requiringSecureCoding: true
        ) as NSData else {
            return nil
        }
        return data
    }

    @objc(PeerCoding)class PeerCoding: NSObject, NSCoding {
        let id: SString
        let filesShared: UInt32
        let kbShared: UInt32

        init(_ myStruct: Peer) {
            id = myStruct.id
            filesShared = myStruct.number_of_files_shd
            kbShared = myStruct.number_of_kb_shd
        }

        required init?(coder aDecoder: NSCoder) {
            id = aDecoder.decodeObject(forKey: "id") as! SString
            filesShared = aDecoder.decodeObject(forKey: "filesShared") as! UInt32
            kbShared = aDecoder.decodeObject(forKey: "kbShared") as! UInt32
        }

        func encode(with coder: NSCoder) {
            coder.encode(id, forKey: "id")
            coder.encode(filesShared, forKey: "filesShared")
            coder.encode(kbShared, forKey: "kbShared")
        }
    }
}
