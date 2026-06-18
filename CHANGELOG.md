# Versions

## 1.0.0

Initial release of `pfx_reader`.

## Features

- Read X.509 certificate fields from a PKCS#12 (`.pfx` / `.p12`) file on Android and iOS.
  - Subject DN and individual fields: Common Name (CN), Organization (O), Organizational Unit (OU), Country (C), Email (E)
  - Issuer DN
  - Validity dates: `notBefore` and `notAfter`
  - Serial number
- Two input methods:
  - `PfxReader.fromBytes(Uint8List, password)` — load from raw bytes (e.g. from an asset or file picker)
  - `PfxReader.fromFile(String path, password)` — load from a file path on disk
- Sign arbitrary data using the private key embedded in the PFX:
  - `PfxReader.signWithBytes(data, pfxBytes, password)`
  - `PfxReader.signWithFile(data, filePath, password)`
  - Supported algorithms: `SHA256withRSA` (default), `SHA1withRSA`, `SHA512withRSA`
- Typed `PfxException` with `PfxErrorCode` enum instead of raw `PlatformException`:
  - `wrongPassword` — incorrect PFX password
  - `fileNotFound` — file path does not exist
  - `importError` — corrupt or unsupported PFX format
  - `keyError` — private key could not be extracted
  - `signError` — signing operation failed
  - `unknown` — unexpected error

## Platform implementation details

- **Android**: uses `java.security.KeyStore` (PKCS12 provider) and `java.security.Signature`
- **iOS**: uses `SecPKCS12Import` for import/signing, and a pure Swift ASN.1 DER parser for certificate field extraction (no macOS-only APIs, fully compatible with iOS simulator and device)

## 1.0.1

- Provide a proper README.

## 1.0.2

- Fix missmatch android package name.

## 1.0.3

- Implement `toJson()`.
- BREAKING: Migrate `toMap()` to `toJson()`

## 1.0.4

- Fix issue when building app bundles with this package.

## 1.0.5

- Rename package bundle name to avoid java reserved keyword.
