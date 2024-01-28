import Foundation

public struct Attachment {
    public let name: String
    public let contentType: String
    public let data: Data

    public init(name: String, contentType: String, data: Data) {
        self.name = name
        self.contentType = contentType
        self.data = data
    }
    
    public init?(filePath path : String) {
        let file = path.fileNameWithoutPath
        guard !file.isEmpty else { return nil }
        let mimeType = MimeType(ext: file.suffix)
        guard let data = Self.getDataFrom(path) else { return nil}
        self = .init(name: file, contentType: mimeType, data: data)
    }
    
    static func getDataFrom(_ path : String) -> Data? {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: path) {
            if let fileHandle = FileHandle(forReadingAtPath: path) {
                let data = fileHandle.readDataToEndOfFile()
                return data
            }
        }
        return nil
    }
}

private extension String {
    /// extract file name from a full path
    var fileNameWithoutPath: String {
        get {
            let segments = self.split(separator: "/")
            return String(segments[segments.count - 1])
        }
    }
    
    /// extract file suffix from a file name
    var suffix: String {
        get {
            let segments = self.split(separator: ".")
            return String(segments[segments.count - 1])
        }
    }
}
