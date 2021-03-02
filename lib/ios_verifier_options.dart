part of masamune_purchase;

/// Validation option for IOS.
class IOSVerifierOptions {
  /// Validation option for IOS.
  ///
  /// [sharedSecret]: Shared secret.
  /// [consumableverificationServer]: URL used for server verification for consumable.
  /// [nonconsumableverificationServer]: URL used for server verification for non-consumable.
  /// [subscriptionverificationServer]: URL used for server verification for subscription.
  const IOSVerifierOptions({
    this.sharedSecret,
    this.consumableVerificationServer,
    this.nonconsumableVerificationServer,
    this.subscriptionVerificationServer,
  });

  /// Shared secret.
  final String? sharedSecret;

  /// URL used for server verification for consumable.
  final String? consumableVerificationServer;

  /// URL used for server verification for non-consumable.
  final String? nonconsumableVerificationServer;

  /// URL used for server verification for subscription.
  final String? subscriptionVerificationServer;
}
