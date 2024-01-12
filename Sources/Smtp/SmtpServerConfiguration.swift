import NIO
import Vapor

public struct SmtpServerConfiguration {
    public var hostname: String
    public var port: Int
    public var username: String
    public var password: String
    public var secure: SmtpSecureChannel
    public var connectTimeout:TimeAmount
    public var helloMethod: HelloMethod

    public init(hostname: String = "",
                port: Int = 465,
                username: String = "",
                password: String = "",
                secure: SmtpSecureChannel = .none,
                connectTimeout: TimeAmount = TimeAmount.seconds(10),
                helloMethod: HelloMethod = .helo
    ) {
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.secure = secure
        self.connectTimeout = connectTimeout
        self.helloMethod = helloMethod
    }
}

public extension SmtpServerConfiguration {
    static var `default`: SmtpServerConfiguration {
       
        return SmtpServerConfiguration(
            hostname: Environment.get("SMTP_ADDRESS") ?? "",
            username: Environment.get("SMTP_USERNAME") ?? "",
            password: Environment.get("SMTP_PASSWORD") ?? "",
            secure: .ssl)
    }
}
