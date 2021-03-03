part of masamune_purchase;

/// Class for managing billing process.
///
/// Initialize by first executing [initialize()].
///
/// Then purchasing item by executing [purchase()].
class NonePurchaseDelegate {
  /// [PurchaseCore] is used as a callback for [onVerify] of [PurchaseCore].
  ///
  /// The signature is verified and the receipt is verified locally.
  ///
  /// [purchase]: PurchaseDetails.
  /// [product]: The purchased product.
  /// [core]: Purchase Core instance.
  static Future<bool> verify(PurchaseDetails purchase, PurchaseProduct product,
          PurchaseModel core) async =>
      true;
}
