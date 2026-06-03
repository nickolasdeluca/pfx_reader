/// Signing algorithms supported by [PfxReader.signWithBytes] and
/// [PfxReader.signWithFile].
enum SignAlgorithm {
  /// SHA-256 with RSA (PKCS#1 v1.5). Default and most widely used.
  sha256WithRSA,

  /// SHA-1 with RSA. Kept for legacy compatibility; prefer SHA-256 or higher.
  sha1WithRSA,

  /// SHA-512 with RSA.
  sha512WithRSA,
}

extension SignAlgorithmName on SignAlgorithm {
  /// The JCA algorithm name used on Android.
  String get jcaName {
    switch (this) {
      case SignAlgorithm.sha256WithRSA:
        return 'SHA256withRSA';
      case SignAlgorithm.sha1WithRSA:
        return 'SHA1withRSA';
      case SignAlgorithm.sha512WithRSA:
        return 'SHA512withRSA';
    }
  }

  /// String token passed over the method channel.
  String get channelName => jcaName;
}
