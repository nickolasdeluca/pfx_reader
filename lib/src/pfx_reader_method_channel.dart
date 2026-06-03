import 'package:flutter/services.dart';
import 'models/certificate_info.dart';
import 'models/pfx_exception.dart';
import 'models/sign_algorithm.dart';
import 'pfx_reader_platform_interface.dart';

class MethodChannelPfxReader extends PfxReaderPlatform {
  static const MethodChannel _channel = MethodChannel('pfx_reader');

  @override
  Future<CertificateInfo> getCertificateInfoFromBytes(
    Uint8List bytes,
    String password,
  ) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getCertificateInfoFromBytes',
        {'pfxBytes': bytes, 'password': password},
      );
      return CertificateInfo.fromMap(result!);
    } on PlatformException catch (e) {
      throw PfxException(pfxErrorCodeFromString(e.code), e.message ?? e.code);
    }
  }

  @override
  Future<CertificateInfo> getCertificateInfoFromFile(
    String filePath,
    String password,
  ) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getCertificateInfoFromFile',
        {'filePath': filePath, 'password': password},
      );
      return CertificateInfo.fromMap(result!);
    } on PlatformException catch (e) {
      throw PfxException(pfxErrorCodeFromString(e.code), e.message ?? e.code);
    }
  }

  @override
  Future<Uint8List> signWithBytes(
    Uint8List data,
    Uint8List pfxBytes,
    String password,
    SignAlgorithm algorithm,
  ) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('signWithBytes', {
        'data': data,
        'pfxBytes': pfxBytes,
        'password': password,
        'algorithm': algorithm.channelName,
      });
      return result!;
    } on PlatformException catch (e) {
      throw PfxException(pfxErrorCodeFromString(e.code), e.message ?? e.code);
    }
  }

  @override
  Future<Uint8List> signWithFile(
    Uint8List data,
    String filePath,
    String password,
    SignAlgorithm algorithm,
  ) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('signWithFile', {
        'data': data,
        'filePath': filePath,
        'password': password,
        'algorithm': algorithm.channelName,
      });
      return result!;
    } on PlatformException catch (e) {
      throw PfxException(pfxErrorCodeFromString(e.code), e.message ?? e.code);
    }
  }
}
