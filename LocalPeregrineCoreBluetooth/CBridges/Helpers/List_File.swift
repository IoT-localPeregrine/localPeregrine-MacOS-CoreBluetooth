import Foundation

extension List_File {
    init?(from list_FileData: NSData) {
        guard let coding = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: List_FileCoding.self,
            from: list_FileData as Data
        ) else {
            return nil
        }
        self.init()
        files = coding.files
    }
    
    func asData() -> NSData? {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: List_FileCoding(self),
            requiringSecureCoding: true
        ) as NSData else {
            return nil
        }
        return data
    }

    @objc(List_FileCoding)class List_FileCoding: NSObject, NSCoding {
        let files: List_File

        init(_ myStruct: List_File) {
//            files = myStruct.tail.pointee
            Lis
        }

        required init?(coder aDecoder: NSCoder) {
            files = aDecoder.decodeObject(forKey: "files") as! List_File
        }

        func encode(with coder: NSCoder) {
            coder.encode(files, forKey: "files")
        }
    }
}
