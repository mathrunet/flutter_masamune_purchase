part of masamune.purchase;

/// Validation option for IOS.
class IOSVerifierOptions {
  /// Shared secret.
  final String sharedSecret;

  /// Validation option for IOS.
  ///
  /// [sharedSecret]: Shared secret.
  const IOSVerifierOptions({this.sharedSecret});
}
