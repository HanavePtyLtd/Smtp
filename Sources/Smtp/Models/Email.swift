import Foundation
import NIO

public class Email {
    public let from: EmailAddress
    public let to: [EmailAddress]
    public let cc: [EmailAddress]?
    public let bcc: [EmailAddress]?
    public let subject: String
    public let body: String
    public let isBodyHtml: Bool
    public let replyTo: EmailAddress?
    public let reference : String?
    public let returnReceipt : EmailAddress?
    
    public var uuid : String = ""
    internal var attachments: [Attachment] = []

    public init(from: EmailAddress,
                to: [EmailAddress],
                cc: [EmailAddress]? = nil,
                bcc: [EmailAddress]? = nil,
                reference : String? = nil,
                subject: String,
                body: String,
                isBodyHtml: Bool = false,
                replyTo: EmailAddress? = nil,
                returnReceipt: EmailAddress? = nil
    ) {
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.body = body
        self.isBodyHtml = isBodyHtml
        self.replyTo = replyTo
        self.reference = reference
        self.returnReceipt = returnReceipt
    }

    public func addAttachment(_ attachment: Attachment) {
        self.attachments.append(attachment)
    }
    public func addAttachments(_ attachments: [Attachment]) {
        for attachment in attachments {
            self.attachments.append(attachment)
        }
    }
}

extension Email {
    internal func write(to out: inout ByteBuffer) {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        let dateFormatted = dateFormatter.string(from: date)

        out.writeString("From: \(self.formatMIME(emailAddress: self.from))\r\n")

        let toAddresses = self.to.map { self.formatMIME(emailAddress: $0) }.joined(separator: ", ")
        out.writeString("To: \(toAddresses)\r\n")

        if let cc = self.cc {
            let ccAddresses = cc.map { self.formatMIME(emailAddress: $0) }.joined(separator: ", ")
            out.writeString("Cc: \(ccAddresses)\r\n")
        }

//        if let bcc = self.bcc {
//            let bccAddresses = bcc.map { self.formatMIME(emailAddress: $0) }.joined(separator: ", ")
//            out.writeString("Bcc: \(bccAddresses)\r\n")
//        }

        if let replyTo = self.replyTo {
            out.writeString("Reply-to: \(self.formatMIME(emailAddress:replyTo))\r\n")
        }

        out.writeString("Subject: \(self.subject)\r\n")
        out.writeString("Date: \(dateFormatted)\r\n")
        self.uuid = "<\(date.timeIntervalSince1970)\(self.from.address.drop { $0 != "@" })>"
        out.writeString("Message-ID: \(self.uuid)\r\n")
        if let reference = self.reference {
            out.writeString("In-Reply-To: \(reference)\r\n")
            out.writeString("References: \(reference)\r\n")
        }
        if let returnReceipt = self.returnReceipt {
            out.writeString("Return-Receipt-To: \(self.formatMIME(emailAddress: returnReceipt))\r\n")
            out.writeString("Disposition-Notification-To: \(self.formatMIME(emailAddress: returnReceipt))\r\n")
        }

        let boundary = self.boundary()
        let altBoundary = "alt" + boundary

        if self.attachments.count > 0 {
            // multipart/mixed with nested multipart/alternative
            out.writeString("Content-Type: multipart/mixed; boundary=\"\(boundary)\"\r\n")
            out.writeString("Mime-Version: 1.0\r\n\r\n")

            out.writeString("--\(boundary)\r\n")
            out.writeString("Content-Type: multipart/alternative; boundary=\"\(altBoundary)\"\r\n\r\n")

            // plain text fallback
            out.writeString("--\(altBoundary)\r\n")
            out.writeString("Content-Type: text/plain; charset=\"UTF-8\"\r\n\r\n")
            out.writeString(self.body.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil) + "\r\n")

            // html version
            if self.isBodyHtml {
                out.writeString("--\(altBoundary)\r\n")
                out.writeString("Content-Type: text/html; charset=\"UTF-8\"\r\n\r\n")
                out.writeString("\(self.body)\r\n")
            }

            out.writeString("--\(altBoundary)--\r\n")

            // attachments
            for attachment in self.attachments {
                out.writeString("--\(boundary)\r\n")
                out.writeString("Content-Type: \(attachment.contentType)\r\n")
                out.writeString("Content-Transfer-Encoding: base64\r\n")
                out.writeString("Content-Disposition: attachment; filename=\"\(attachment.name)\"\r\n\r\n")
                out.writeString("\(attachment.data.base64EncodedString())\r\n")
            }

            out.writeString("--\(boundary)--\r\n")
        } else if self.isBodyHtml {
            // multipart/alternative without attachments
            out.writeString("Content-Type: multipart/alternative; boundary=\"\(altBoundary)\"\r\n")
            out.writeString("Mime-Version: 1.0\r\n\r\n")

            // plain text fallback
            out.writeString("--\(altBoundary)\r\n")
            out.writeString("Content-Type: text/plain; charset=\"UTF-8\"\r\n\r\n")
            out.writeString(self.body.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil) + "\r\n")

            // html version
            out.writeString("--\(altBoundary)\r\n")
            out.writeString("Content-Type: text/html; charset=\"UTF-8\"\r\n\r\n")
            out.writeString("\(self.body)\r\n")
            out.writeString("--\(altBoundary)--\r\n")
        } else {
            // plain text only
            out.writeString("Content-Type: text/plain; charset=\"UTF-8\"\r\n")
            out.writeString("Mime-Version: 1.0\r\n\r\n")
            out.writeString(self.body)
        }
        out.writeString("\r\n.")
    }

    private func boundary() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }

    func formatMIME(emailAddress: EmailAddress) -> String {
        if let name = emailAddress.name {
            return "\(name) <\(emailAddress.address)>"
        } else {
            return emailAddress.address
        }
    }
}
