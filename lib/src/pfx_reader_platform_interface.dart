import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models/certificate_info.dart';
import 'models/sign_algorithm.dart';
import 'pfx_reader_method_channel.dart';

abstract class PfxReaderPlatform extends PlatformInterface {
  PfxReaderPlatform() : super(token: _token);

  static final Object _token = Object();

  static PfxReaderPlatform _instance = MethodChannelPfxReader();

  static PfxReaderPlatform get instance => _instance;

  static set instance(PfxReaderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Parses certificate info from raw PFX [bytes].
  Future<CertificateInfo> getCertificateInfoFromBytes(
    Uint8List bytes,
    String password,
  );

  /// Parses certificate info from a PFX file at [filePath].
  Future<CertificateInfo> getCertificateInfoFromFile(
    String filePath,
    String password,
  );

  /// Signs [data] using the private key embedded in the PFX [pfxBytes].
  Future<Uint8List> signWithBytes(
    Uint8List data,
    Uint8List pfxBytes,
    String password,
    SignAlgorithm algorithm,
  );

  /// Signs [data] using the private key embedded in the PFX file at [filePath].
  Future<Uint8List> signWithFile(
    Uint8List data,
    String filePath,
    String password,
    SignAlgorithm algorithm,
  );
}
