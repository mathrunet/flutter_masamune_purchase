part of masamune.purchase;

/// Validation option for IOS.
class IOSVerifierOptions {
  /// Shared secret.
  final String sharedSecret;

  /// URL used for server verification.
  final String verificationServer;

  /// Validation option for IOS.
  ///
  /// [sharedSecret]: Shared secret.
  /// [verificationServer]: URL used for server verification.
  const IOSVerifierOptions({this.sharedSecret, this.verificationServer});
}
