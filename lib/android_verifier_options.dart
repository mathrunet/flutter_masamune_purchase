part of masamune_purchase;

/// Validation option for Android.
class AndroidVerifierOptions {
  /// Validation option for Android.
  ///
  /// [clientId]: Client ID.
  /// [publicKey]: Public key for license.
  /// [clientSecret]: Client secret.
  /// [consumableverificationServer]: URL used for server verification for consumable.
  /// [nonconsumableverificationServer]: URL used for server verification for non-consumable.
  /// [subscriptionverificationServer]: URL used for server verification for subscription.
  const AndroidVerifierOptions({
    this.clientId,
    this.publicKey,
    this.clientSecret,
    this.consumableVerificationServer,
    this.nonconsumableVerificationServer,
    this.subscriptionVerificationServer,
  });

  /// Client ID.
  final String? clientId;

  /// Client secret.
  final String? clientSecret;

  /// Public key for license.
  final String? publicKey;

  /// URL used for server verification for consumable.
  final String? consumableVerificationServer;

  /// URL used for server verification for non-consumable.
  final String? nonconsumableVerificationServer;

  /// URL used for server verification for subscription.
  final String? subscriptionVerificationServer;
}
