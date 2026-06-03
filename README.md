# pfx_reader

A Flutter plugin to read PKCS#12 (`.pfx` / `.p12`) certificate fields and sign data using the embedded private key. Supports **Android** and **iOS**.

## Features

- Extract X.509 certificate fields from a PFX/PKCS#12 file:
  - Subject DN and individual fields: Common Name (CN), Organization (O), Organizational Unit (OU), Country (C), Email (E)
  - Issuer DN
  - Validity dates (`notBefore`, `notAfter`)
  - Serial number
- Two input methods:
  - Load from raw bytes (e.g. from an asset or file picker)
  - Load from a file path on disk
- Sign arbitrary data using the private key embedded in the PFX
- Supported signing algorithms: `SHA256withRSA` (default), `SHA1withRSA`, `SHA512withRSA`
- Typed `PfxException` with `PfxErrorCode` enum — no raw `PlatformException` string-matching needed

## Platform support

| Android | iOS |
|:-------:|:---:|
| ✅      | ✅  |

- **Android**: uses `java.security.KeyStore` (PKCS12 provider) and `java.security.Signature`
- **iOS**: uses `SecPKCS12Import` for import/signing, and a pure Swift ASN.1 DER parser for certificate field extraction (fully compatible with simulator and device)

## Installation

Add `pfx_reader` to your `pubspec.yaml`:

```yaml
dependencies:
  pfx_reader: ^1.0.0
```

Then run:

```sh
flutter pub get
```

## Usage

### Read certificate info from bytes

```dart
import 'package:pfx_reader/pfx_reader.dart';

final Uint8List pfxBytes = ...; // load from asset, file picker, etc.

try {
  final CertificateInfo info = await PfxReader.fromBytes(pfxBytes, 'password');

  print(info.commonName);    // e.g. "John Doe"
  print(info.organization);  // e.g. "Acme Corp"
  print(info.notAfter);      // expiration date (UTC)
  print(info.serialNumber);  // certificate serial number
  print(info.subjectDN);     // full subject DN string
  print(info.issuerDN);      // full issuer DN string
} on PfxException catch (e) {
  print('${e.code}: ${e.message}');
}
```

### Read certificate info from a file path

```dart
try {
  final CertificateInfo info = await PfxReader.fromFile('/path/to/cert.pfx', 'password');
  print(info.commonName);
} on PfxException catch (e) {
  print('${e.code}: ${e.message}');
}
```

### Sign data from bytes

```dart
final Uint8List dataToSign = ...; // the raw bytes you want to sign
final Uint8List pfxBytes   = ...; // your PFX certificate bytes

try {
  final Uint8List signature = await PfxReader.signWithBytes(
    dataToSign,
    pfxBytes,
    'password',
    algorithm: SignAlgorithm.sha256WithRSA, // optional, default is sha256WithRSA
  );
} on PfxException catch (e) {
  print('${e.code}: ${e.message}');
}
```

### Sign data from a file path

```dart
final Uint8List signature = await PfxReader.signWithFile(
  dataToSign,
  '/path/to/cert.pfx',
  'password',
  algorithm: SignAlgorithm.sha512WithRSA,
);
```

## API reference

### `PfxReader`

| Method | Description |
| -------- | ------------- |
| `fromBytes(Uint8List bytes, String password)` | Parse certificate fields from raw PFX bytes |
| `fromFile(String filePath, String password)` | Parse certificate fields from a PFX file path |
| `signWithBytes(Uint8List data, Uint8List pfxBytes, String password, {SignAlgorithm algorithm})` | Sign data using the private key from PFX bytes |
| `signWithFile(Uint8List data, String filePath, String password, {SignAlgorithm algorithm})` | Sign data using the private key from a PFX file |

### `CertificateInfo`

| Field | Type | Description |
| ------- | ------ | ------------- |
| `subjectDN` | `String` | Full subject Distinguished Name |
| `issuerDN` | `String` | Full issuer Distinguished Name |
| `notBefore` | `DateTime` | Certificate validity start (UTC) |
| `notAfter` | `DateTime` | Certificate validity end / expiration (UTC) |
| `serialNumber` | `String` | Serial number (decimal string) |
| `commonName` | `String?` | Common Name (CN) |
| `organization` | `String?` | Organization (O) |
| `organizationalUnit` | `String?` | Organizational Unit (OU) |
| `country` | `String?` | Country (C) |
| `email` | `String?` | Email address (E / emailAddress) |

### `SignAlgorithm`

| Value | Description |
| ------- | ------------- |
| `SignAlgorithm.sha256WithRSA` | SHA-256 with RSA PKCS#1 v1.5 (default) |
| `SignAlgorithm.sha1WithRSA` | SHA-1 with RSA (legacy) |
| `SignAlgorithm.sha512WithRSA` | SHA-512 with RSA |

### `PfxException` / `PfxErrorCode`

| Code | Description |
| ------ | ------------- |
| `wrongPassword` | Incorrect PFX password |
| `fileNotFound` | File path does not exist or cannot be read |
| `importError` | Corrupt or unsupported PFX format |
| `keyError` | Private key could not be extracted |
| `signError` | Signing operation failed |
| `unknown` | Unexpected error |
