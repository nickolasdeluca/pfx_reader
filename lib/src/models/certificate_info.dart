/// Holds parsed X.509 certificate fields extracted from a PFX/PKCS#12 file.
class CertificateInfo {
  /// Full Distinguished Name of the subject (e.g. "CN=John, O=Acme, C=BR").
  final String subjectDN;

  /// Full Distinguished Name of the issuer CA.
  final String issuerDN;

  /// The date from which the certificate is valid.
  final DateTime notBefore;

  /// The date on which the certificate expires.
  final DateTime notAfter;

  /// Certificate serial number (decimal string).
  final String serialNumber;

  /// Common Name (CN) — typically the person/entity name.
  final String? commonName;

  /// Organization (O).
  final String? organization;

  /// Organizational Unit (OU).
  final String? organizationalUnit;

  /// Country (C).
  final String? country;

  /// Email address (E / emailAddress), if present in the subject.
  final String? email;

  const CertificateInfo({
    required this.subjectDN,
    required this.issuerDN,
    required this.notBefore,
    required this.notAfter,
    required this.serialNumber,
    this.commonName,
    this.organization,
    this.organizationalUnit,
    this.country,
    this.email,
  });

  factory CertificateInfo.fromJson(Map<Object?, Object?> map) {
    return CertificateInfo(
      subjectDN: map['subjectDN'] as String? ?? '',
      issuerDN: map['issuerDN'] as String? ?? '',
      notBefore: DateTime.fromMillisecondsSinceEpoch(
        (map['notBefore'] as int?) ?? 0,
        isUtc: true,
      ),
      notAfter: DateTime.fromMillisecondsSinceEpoch(
        (map['notAfter'] as int?) ?? 0,
        isUtc: true,
      ),
      serialNumber: map['serialNumber'] as String? ?? '',
      commonName: map['commonName'] as String?,
      organization: map['organization'] as String?,
      organizationalUnit: map['organizationalUnit'] as String?,
      country: map['country'] as String?,
      email: map['email'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'subjectDN': subjectDN,
      'issuerDN': issuerDN,
      'notBefore': notBefore.millisecondsSinceEpoch,
      'notAfter': notAfter.millisecondsSinceEpoch,
      'serialNumber': serialNumber,
      'commonName': commonName,
      'organization': organization,
      'organizationalUnit': organizationalUnit,
      'country': country,
      'email': email,
    };
  }
}
