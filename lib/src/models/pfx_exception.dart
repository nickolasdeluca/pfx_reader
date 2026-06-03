/// Typed exception thrown by [PfxReader] operations.
///
/// Replaces raw [PlatformException] so callers can `catch (e on PfxException)`
/// and branch on [code] without string-matching.
class PfxException implements Exception {
  /// Machine-readable error code (matches the native error code string).
  final PfxErrorCode code;

  /// Human-readable description.
  final String message;

  const PfxException(this.code, this.message);

  @override
  String toString() => 'PfxException(${code.name}): $message';
}

enum PfxErrorCode {
  /// The PFX password is wrong.
  wrongPassword,

  /// The file path provided does not exist or cannot be read.
  fileNotFound,

  /// The PFX data is corrupt or in an unsupported format.
  importError,

  /// The private key could not be extracted from the PFX.
  keyError,

  /// The signing operation failed.
  signError,

  /// An unexpected error occurred.
  unknown,
}

/// Maps native error code strings to [PfxErrorCode].
PfxErrorCode pfxErrorCodeFromString(String? code) {
  switch (code) {
    case 'WRONG_PASSWORD':
      return PfxErrorCode.wrongPassword;
    case 'FILE_NOT_FOUND':
      return PfxErrorCode.fileNotFound;
    case 'IMPORT_ERROR':
      return PfxErrorCode.importError;
    case 'KEY_ERROR':
      return PfxErrorCode.keyError;
    case 'SIGN_ERROR':
      return PfxErrorCode.signError;
    default:
      return PfxErrorCode.unknown;
  }
}
