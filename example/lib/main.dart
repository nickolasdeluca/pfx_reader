import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:pfx_reader/pfx_reader.dart';
import 'package:pfx_reader_example/certificate_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CertificateInfo? _certInfo;
  String _status = 'No certificate loaded';

  Future<void> _loadCertificate() async {
    _certInfo = null;
    // Replace with a real PFX bytes source and password in your app.
    // For example, load from assets or file picker.
    final bytes = await rootBundle.load('assets/pfx/cert.pfx');

    try {
      _certInfo = await parseCertificateInfo(
        bytes.buffer.asUint8List(),
        'password',
      );
    } catch (e) {
      setState(() {
        _status = 'Error loading certificate: ${e.toString()}';
      });
      return;
    }

    setState(() {
      _status = _certInfo != null
          ? 'Certificate loaded successfully'
          : 'Use PfxReader.fromBytes() or PfxReader.fromFile() to load a certificate.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('PfxReader example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_status),
              if (_certInfo != null) ...[
                const SizedBox(height: 16),
                Text('CN: ${_certInfo!.commonName}'),
                Text('Issuer: ${_certInfo!.issuerDN}'),
                Text('Expires: ${_certInfo!.notAfter}'),
                Text('Serial: ${_certInfo!.serialNumber}'),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadCertificate,
                child: const Text('Load certificate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
