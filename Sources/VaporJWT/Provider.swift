import Vapor
import JWT

/// Adds required JWT objects to your application
/// like token Signers
public final class Provider: Vapor.Provider {
    public let signer: Signer
    public init(signer: Signer) {
        self.signer = signer
    }

    /// Parses a `jwt.json` config file to create
    /// the JWT objects
    public convenience init(config: Config) throws {
        guard let jwt = config["jwt"]?.object else {
            struct NoJWTConfig: Error, CustomStringConvertible {
                var description = "No `jwt.json` config file found."
            }
            throw ConfigError.unspecified(NoJWTConfig())
        }

        guard let signerConfig = jwt["signer"]?.object else {
            throw ConfigError.missing(key: ["signer"], file: "jwt", desiredType: Dictionary<String, Any>.self)
        }

        guard let signerType = signerConfig["type"]?.string else {
            throw ConfigError.missing(key: ["signer", "type"], file: "jwt", desiredType: String.self)
        }

        let signer: Signer

        switch signerType {
        case "unsigned":
            signer = Unsigned()
        case "hmac":
            guard let algorithm = signerConfig["algorithm"]?.string else {
                throw ConfigError.missing(key: ["signer", "algorithm"], file: "jwt", desiredType: String.self)
            }

            guard let key = signerConfig["key"]?.string else {
                throw ConfigError.missing(key: ["signer", "key"], file: "jwt", desiredType: String.self)
            }

            let bytes = key.bytes

            switch algorithm {
            case "hs256":
                signer = HS256(key: bytes)
            case "hs384":
                signer = HS384(key: bytes)
            case "hs512":
                signer = HS512(key: bytes)
            default:
                throw ConfigError.unsupported(value: algorithm, key: ["signer", "algorithm"], file: "jwt")
            }
        case "rsa":
            guard let algorithm = signerConfig["algorithm"]?.string else {
                throw ConfigError.missing(key: ["signer", "algorithm"], file: "jwt", desiredType: String.self)
            }

            guard let key = signerConfig["key"]?.string else {
                throw ConfigError.missing(key: ["signer", "key"], file: "jwt", desiredType: String.self)
            }

            let bytes = key.bytes.base64Decoded

            switch algorithm {
            case "rs256":
                signer = try RS256(key: bytes)
            case "rs384":
                signer = try RS384(key: bytes)
            case "rs512":
                signer = try RS512(key: bytes)
            default:
                throw ConfigError.unsupported(value: algorithm, key: ["signer", "algorithm"], file: "jwt")
            }
        case "esdca":
            guard let algorithm = signerConfig["algorithm"]?.string else {
                throw ConfigError.missing(key: ["signer", "algorithm"], file: "jwt", desiredType: String.self)
            }

            guard let key = signerConfig["key"]?.string else {
                throw ConfigError.missing(key: ["signer", "key"], file: "jwt", desiredType: String.self)
            }

            let bytes = key.bytes

            switch algorithm {
            case "es256":
                signer = ES256(key: bytes)
            case "es384":
                signer = ES384(key: bytes)
            case "es512":
                signer = ES512(key: bytes)
            default:
                throw ConfigError.unsupported(value: algorithm, key: ["signer", "algorithm"], file: "jwt")
            }
        default:
            throw ConfigError.unsupported(value: signerType, key: ["signer", "type"], file: "jwt")
        }

        self.init(signer: signer)
    }

    /// Called to prepare the Droplet.
    public func boot(_ drop: Droplet) {
        drop.set(signer)
    }

    /// Called after the Droplet has completed
    /// initialization and all provided items
    /// have been accepted.
    public func afterInit(_ drop: Droplet) {

    }

    /// Called before the Droplet begins serving
    /// which is @noreturn.
    public func beforeRun(_ drop: Droplet) {

    }
}
