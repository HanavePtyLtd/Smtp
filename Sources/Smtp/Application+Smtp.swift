import Vapor

extension Application {
    public var smtp: Smtp {
        .init(application: self)
    }

    public struct Smtp {
        let application: Application

        struct ConfigurationKey: StorageKey {
            typealias Value = SmtpServerConfiguration
        }

        public var configuration: SmtpServerConfiguration {
            get {
                if let config = self.application.storage[ConfigurationKey.self] {
                    return config
                }
                fatalError("Can't use SMTP Without a configuration")
            }
            nonmutating set {
                self.application.storage[ConfigurationKey.self] = newValue
            }
        }
    }
}
