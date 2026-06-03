import Flutter
import Foundation
import Security

public class PfxReaderPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pfx_reader", binaryMessenger: registrar.messenger())
        let instance = PfxReaderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARG", message: "Arguments must be a dictionary", details: nil))
            return
        }

        switch call.method {
        case "getCertificateInfoFromBytes":
            guard let flutterData = args["pfxBytes"] as? FlutterStandardTypedData,
                  let password = args["password"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "pfxBytes and password are required", details: nil))
                return
            }
            handleCertInfo(pfxData: flutterData.data, password: password, result: result)

        case "getCertificateInfoFromFile":
            guard let filePath = args["filePath"] as? String,
                  let password = args["password"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "filePath and password are required", details: nil))
                return
            }
            guard let pfxData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Could not read file: \(filePath)", details: nil))
                return
            }
            handleCertInfo(pfxData: pfxData, password: password, result: result)

        case "signWithBytes":
            guard let flutterData = args["pfxBytes"] as? FlutterStandardTypedData,
                  let flutterPayload = args["data"] as? FlutterStandardTypedData,
                  let password = args["password"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "data, pfxBytes and password are required", details: nil))
                return
            }
            let algorithm = args["algorithm"] as? String ?? "SHA256withRSA"
            handleSign(pfxData: flutterData.data, data: flutterPayload.data, password: password, algorithm: algorithm, result: result)

        case "signWithFile":
            guard let filePath = args["filePath"] as? String,
                  let flutterPayload = args["data"] as? FlutterStandardTypedData,
                  let password = args["password"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "data, filePath and password are required", details: nil))
                return
            }
            guard let pfxData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Could not read file: \(filePath)", details: nil))
                return
            }
            let algorithm = args["algorithm"] as? String ?? "SHA256withRSA"
            handleSign(pfxData: pfxData, data: flutterPayload.data, password: password, algorithm: algorithm, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Certificate info

    private func handleCertInfo(pfxData: Data, password: String, result: @escaping FlutterResult) {
        guard let (_, certificate) = importPkcs12(pfxData: pfxData, password: password, result: result) else { return }
        let derData = SecCertificateCopyData(certificate) as Data
        let f = X509Parser.parse(derData)
        result([
            "subjectDN"         : f.subjectDN as Any,
            "issuerDN"          : f.issuerDN as Any,
            "notBefore"         : f.notBeforeMs as Any,
            "notAfter"          : f.notAfterMs as Any,
            "serialNumber"      : f.serialNumber as Any,
            "commonName"        : f.commonName as Any,
            "organization"      : f.organization as Any,
            "organizationalUnit": f.organizationalUnit as Any,
            "country"           : f.country as Any,
            "email"             : f.email as Any,
        ])
    }

    // MARK: - Signing

    private func handleSign(pfxData: Data, data: Data, password: String, algorithm: String, result: @escaping FlutterResult) {
        guard let (identity, _) = importPkcs12(pfxData: pfxData, password: password, result: result) else { return }
        var privateKey: SecKey?
        let copyStatus = SecIdentityCopyPrivateKey(identity, &privateKey)
        guard copyStatus == errSecSuccess, let key = privateKey else {
            result(FlutterError(code: "KEY_ERROR", message: "Could not extract private key (OSStatus \(copyStatus))", details: nil))
            return
        }
        let secAlgorithm = secKeyAlgorithm(for: algorithm)
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(key, secAlgorithm, data as CFData, &error) else {
            let desc = error?.takeRetainedValue().localizedDescription ?? "Unknown signing error"
            result(FlutterError(code: "SIGN_ERROR", message: desc, details: nil))
            return
        }
        result(FlutterStandardTypedData(bytes: signature as Data))
    }

    // MARK: - Helpers

    private func importPkcs12(pfxData: Data, password: String, result: @escaping FlutterResult) -> (SecIdentity, SecCertificate)? {
        let options: [String: Any] = [kSecImportExportPassphrase as String: password]
        var items: CFArray?
        let status = SecPKCS12Import(pfxData as CFData, options as CFDictionary, &items)
        guard status == errSecSuccess else {
            let code = (status == errSecAuthFailed) ? "WRONG_PASSWORD" : "IMPORT_ERROR"
            let message = (status == errSecAuthFailed)
                ? "Incorrect password for the PFX file."
                : "SecPKCS12Import failed (OSStatus \(status)). The file may be corrupt or in an unsupported format."
            result(FlutterError(code: code, message: message, details: nil))
            return nil
        }
        guard let itemArray = items as? [[String: Any]],
              let item = itemArray.first,
              item[kSecImportItemIdentity as String] != nil else {
            result(FlutterError(code: "IMPORT_ERROR", message: "No identity found in PFX file.", details: nil))
            return nil
        }
        // CFTypeRef-based types cannot use conditional cast; presence was checked above.
        let identity = item[kSecImportItemIdentity as String] as! SecIdentity
        var certificate: SecCertificate?
        SecIdentityCopyCertificate(identity, &certificate)
        guard let cert = certificate else {
            result(FlutterError(code: "IMPORT_ERROR", message: "Could not copy certificate from identity", details: nil))
            return nil
        }
        return (identity, cert)
    }

    private func secKeyAlgorithm(for jcaName: String) -> SecKeyAlgorithm {
        switch jcaName.uppercased() {
        case "SHA1WITHRSA"  : return .rsaSignatureMessagePKCS1v15SHA1
        case "SHA512WITHRSA": return .rsaSignatureMessagePKCS1v15SHA512
        default             : return .rsaSignatureMessagePKCS1v15SHA256
        }
    }
}

// =============================================================================
// Pure ASN.1 DER X.509 parser — works on iOS and macOS without private APIs
// =============================================================================

struct X509Fields {
    var subjectDN: String = ""
    var issuerDN: String = ""
    var notBeforeMs: Int?
    var notAfterMs: Int?
    var serialNumber: String = ""
    var commonName: String?
    var organization: String?
    var organizationalUnit: String?
    var country: String?
    var email: String?
}

struct X509Parser {

    // Parses a DER-encoded X.509 certificate into X509Fields.
    static func parse(_ der: Data) -> X509Fields {
        var r = DerReader(data: der)
        var f = X509Fields()

        // Certificate  ::=  SEQUENCE { tbsCertificate, signatureAlgorithm, signature }
        guard case let .sequence(cert) = r.next(), let tbsElem = cert.first,
              case let .sequence(tbs) = tbsElem else { return f }

        var i = 0

        // version  [0] EXPLICIT INTEGER OPTIONAL
        if i < tbs.count, case .contextExplicit(0, _) = tbs[i] { i += 1 }

        // serialNumber  INTEGER
        if i < tbs.count, case let .integer(bytes) = tbs[i] {
            f.serialNumber = formatSerial(bytes); i += 1
        }

        // signature  AlgorithmIdentifier — skip
        i += 1

        // issuer  Name
        if i < tbs.count, case let .sequence(issuerSets) = tbs[i] {
            let (dn, _) = parseName(issuerSets); f.issuerDN = dn; i += 1
        }

        // validity  SEQUENCE { notBefore, notAfter }
        if i < tbs.count, case let .sequence(validity) = tbs[i] {
            if validity.count > 0 { f.notBeforeMs = parseTime(validity[0]) }
            if validity.count > 1 { f.notAfterMs  = parseTime(validity[1]) }
            i += 1
        }

        // subject  Name
        if i < tbs.count, case let .sequence(subjectSets) = tbs[i] {
            let (dn, attrs) = parseName(subjectSets)
            f.subjectDN          = dn
            f.commonName         = attrs["CN"]
            f.organization       = attrs["O"]
            f.organizationalUnit = attrs["OU"]
            f.country            = attrs["C"]
            f.email              = attrs["E"] ?? attrs["EMAILADDRESS"]
        }

        return f
    }

    // Parses a Name (SEQUENCE OF RDN SET) into a DN string and an attribute dict.
    private static func parseName(_ rdnSets: [DerValue]) -> (String, [String: String]) {
        var parts: [String] = []
        var attrs: [String: String] = [:]
        for rdn in rdnSets {
            guard case let .set(atvs) = rdn else { continue }
            for atv in atvs {
                guard case let .sequence(atvContents) = atv, atvContents.count >= 2,
                      case let .oid(oidBytes) = atvContents[0] else { continue }
                let label = oidLabel(oidBytes)
                let value = stringValue(atvContents[1])
                parts.append("\(label)=\(value)")
                attrs[label] = value
            }
        }
        return (parts.joined(separator: ", "), attrs)
    }

    // Maps well-known OID byte sequences to short labels.
    private static func oidLabel(_ b: [UInt8]) -> String {
        if b == [0x55, 0x04, 0x03] { return "CN"  }   // 2.5.4.3
        if b == [0x55, 0x04, 0x06] { return "C"   }   // 2.5.4.6
        if b == [0x55, 0x04, 0x07] { return "L"   }   // 2.5.4.7
        if b == [0x55, 0x04, 0x08] { return "ST"  }   // 2.5.4.8
        if b == [0x55, 0x04, 0x0A] { return "O"   }   // 2.5.4.10
        if b == [0x55, 0x04, 0x0B] { return "OU"  }   // 2.5.4.11
        // emailAddress: 1.2.840.113549.1.9.1
        if b == [0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x01] { return "E" }
        return decodeOid(b)
    }

    // Decodes OID bytes to dotted-decimal notation.
    private static func decodeOid(_ b: [UInt8]) -> String {
        guard !b.isEmpty else { return "" }
        var out = [Int(b[0]) / 40, Int(b[0]) % 40]
        var acc = 0
        for byte in b.dropFirst() {
            acc = (acc << 7) | Int(byte & 0x7F)
            if byte & 0x80 == 0 { out.append(acc); acc = 0 }
        }
        return out.map(String.init).joined(separator: ".")
    }

    // Extracts a String from any DER string-typed value.
    private static func stringValue(_ v: DerValue) -> String {
        switch v {
        case let .utf8String(s), let .printableString(s),
             let .ia5String(s), let .t61String(s), let .bmpString(s): return s
        default: return ""
        }
    }

    // Converts UTCTime / GeneralizedTime to Unix epoch milliseconds.
    private static func parseTime(_ v: DerValue) -> Int? {
        let str: String
        let fmt = DateFormatter()
        fmt.locale   = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "UTC")
        switch v {
        case let .utcTime(s):
            str = s; fmt.dateFormat = "yyMMddHHmmss'Z'"
        case let .generalizedTime(s):
            str = s; fmt.dateFormat = "yyyyMMddHHmmss'Z'"
        default:
            return nil
        }
        guard let date = fmt.date(from: str) else { return nil }
        return Int(date.timeIntervalSince1970 * 1000)
    }

    // Formats serial number bytes as colon-separated hex, dropping leading 0x00.
    private static func formatSerial(_ bytes: [UInt8]) -> String {
        var b = bytes
        if b.count > 1 && b.first == 0x00 { b.removeFirst() }
        return b.map { String(format: "%02X", $0) }.joined(separator: ":")
    }
}

// =============================================================================
// ASN.1 DER value model
// =============================================================================

indirect enum DerValue {
    case boolean(Bool)
    case integer([UInt8])
    case bitString([UInt8])
    case octetString([UInt8])
    case oid([UInt8])
    case utf8String(String)
    case printableString(String)
    case ia5String(String)
    case t61String(String)
    case bmpString(String)
    case utcTime(String)
    case generalizedTime(String)
    case sequence([DerValue])
    case set([DerValue])
    case contextExplicit(UInt8, [DerValue])
    case unknown
}

// =============================================================================
// Minimal DER reader
// =============================================================================

struct DerReader {
    private let data: Data
    private var offset: Int

    init(data: Data) { self.data = data; self.offset = 0 }

    mutating func next() -> DerValue {
        guard offset < data.count else { return .unknown }
        let tag = data[offset]; offset += 1
        guard let length = readLength(), offset + length <= data.count else { return .unknown }
        let slice = data.subdata(in: offset ..< offset + length)
        offset += length
        return decode(tag: tag, slice: slice)
    }

    private func decode(tag: UInt8, slice: Data) -> DerValue {
        switch tag {
        case 0x01: return .boolean(slice.first != 0x00)
        case 0x02: return .integer([UInt8](slice))
        case 0x03: return .bitString([UInt8](slice.dropFirst()))   // drop unused-bits byte
        case 0x04: return .octetString([UInt8](slice))
        case 0x06: return .oid([UInt8](slice))
        case 0x0C: return .utf8String(str(slice, .utf8))
        case 0x13: return .printableString(str(slice, .utf8))
        case 0x14: return .t61String(str(slice, .isoLatin1))
        case 0x16: return .ia5String(str(slice, .ascii))
        case 0x17: return .utcTime(str(slice, .ascii))
        case 0x18: return .generalizedTime(str(slice, .ascii))
        case 0x1E: return .bmpString(str(slice, .utf16BigEndian))
        case 0x30: return .sequence(children(of: slice))
        case 0x31: return .set(children(of: slice))
        default:
            // context-specific constructed: tag class bits 7-6 == 10, bit 5 == 1
            if (tag & 0xC0) == 0x80 && (tag & 0x20) != 0 {
                return .contextExplicit(tag & 0x1F, children(of: slice))
            }
            return .unknown
        }
    }

    private func children(of slice: Data) -> [DerValue] {
        var r = DerReader(data: slice)
        var out: [DerValue] = []
        while r.offset < slice.count { out.append(r.next()) }
        return out
    }

    private mutating func readLength() -> Int? {
        guard offset < data.count else { return nil }
        let first = data[offset]; offset += 1
        if first & 0x80 == 0 { return Int(first) }
        let n = Int(first & 0x7F)
        guard n > 0, offset + n <= data.count else { return nil }
        var len = 0
        for _ in 0 ..< n { len = (len << 8) | Int(data[offset]); offset += 1 }
        return len
    }

    private func str(_ data: Data, _ encoding: String.Encoding) -> String {
        String(data: data, encoding: encoding) ?? ""
    }
}

