part of masamune.purchase;

/// Validation option for Android.
class AndroidVerifierOptions {
  /// Client ID.
  final String clientId;

  /// Client secret.
  final String clientSecret;

  /// Public key for license.
  final String publicKey;

  /// Refresh token.
  final String refreshToken;

  /// Validation option for Android.
  ///
  /// [clientId]: Client ID.
  /// [publicKey]: Public key for license.
  /// [clientSecret]: Client secret.
  /// [refreshToken]: Refresh token.
  const AndroidVerifierOptions(
      {this.clientId, this.publicKey, this.clientSecret, this.refreshToken});
}
