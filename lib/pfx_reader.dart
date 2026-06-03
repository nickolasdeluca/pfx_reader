import 'dart:typed_data';
import 'src/models/certificate_info.dart';
import 'src/models/sign_algorithm.dart';
import 'src/pfx_reader_platform_interface.dart';

export 'src/models/certificate_info.dart';
export 'src/models/pfx_exception.dart';
export 'src/models/sign_algorithm.dart';

/// Entry-point for reading PFX/PKCS#12 certificate data and signing content
/// using the embedded private key.
///
/// ## Read certificate info
/// ```dart
/// // From raw bytes
/// final info = await PfxReader.fromBytes(pfxBytes, 'password');
///
/// // From a file path
/// final info = await PfxReader.fromFile('/path/to/cert.pfx', 'password');
///
/// print(info.commonName);   // e.g. "João da Silva"
/// print(info.notAfter);     // expiration date
/// ```
///
/// ## Sign data
/// ```dart
/// final signature = await PfxReader.signWithBytes(
///   dataToSign,
///   pfxBytes,
///   'password',
/// );
/// ```
class PfxReader {
  PfxReader._();

  /// Reads certificate fields from raw PFX [bytes] protected by [password].
  static Future<CertificateInfo> fromBytes(Uint8List bytes, String password) =>
      PfxReaderPlatform.instance.getCertificateInfoFromBytes(bytes, password);

  /// Reads certificate fields from the PFX file at [filePath] protected by
  /// [password].
  static Future<CertificateInfo> fromFile(String filePath, String password) =>
      PfxReaderPlatform.instance.getCertificateInfoFromFile(filePath, password);

  /// Signs [data] using the private key from raw PFX [pfxBytes].
  ///
  /// Returns the raw signature bytes (PKCS#1 format).
  static Future<Uint8List> signWithBytes(
    Uint8List data,
    Uint8List pfxBytes,
    String password, {
    SignAlgorithm algorithm = SignAlgorithm.sha256WithRSA,
  }) => PfxReaderPlatform.instance.signWithBytes(
    data,
    pfxBytes,
    password,
    algorithm,
  );

  /// Signs [data] using the private key from the PFX file at [filePath].
  ///
  /// Returns the raw signature bytes (PKCS#1 format).
  static Future<Uint8List> signWithFile(
    Uint8List data,
    String filePath,
    String password, {
    SignAlgorithm algorithm = SignAlgorithm.sha256WithRSA,
  }) => PfxReaderPlatform.instance.signWithFile(
    data,
    filePath,
    password,
    algorithm,
  );
}
