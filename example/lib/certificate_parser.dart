import 'package:flutter/services.dart';
import 'package:pfx_reader/pfx_reader.dart';

Future<CertificateInfo?> parseCertificateInfo(
  Uint8List pfxBytes,
  String password,
) async {
  CertificateInfo? info;

  try {
    info = await PfxReader.fromBytes(pfxBytes, password);
  } catch (_) {
    rethrow;
  }

  return info;
}
