part of masamune.purchase;

/// Validation option for Android.
class AndroidVerifierOptions {
  /// Client ID.
  final String clientId;

  /// Client secret.
  final String clientSecret;

  /// Public key for license.
  final String publicKey;

  /// URL used for server verification.
  final String verificationServer;

  /// Validation option for Android.
  ///
  /// [clientId]: Client ID.
  /// [publicKey]: Public key for license.
  /// [clientSecret]: Client secret.
  /// [verificationServer]: URL used for server verification.
  const AndroidVerifierOptions(
      {this.clientId, this.publicKey, this.clientSecret, this.verificationServer});
}
