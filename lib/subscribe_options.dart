part of masamune_purchase;

/// Options for subscription.
class SubscribeOptions {
  /// Options for subscription.
  ///
  /// [data]: Collection that stores log data for subscriptions.
  /// [task]: Asynchronous data for the collection that contains the subscription log data.
  /// [expiryDateKey]: Expiration date key.
  /// [renewDuration]: The time to start the update.
  /// [tokenKey]: Token key.
  /// [packageNameKey]: Package name key.
  /// [productIDKey]: Product ID key.
  /// [orderIDKey]: Order ID key.
  /// [userIDKey]: User ID key.
  /// [expiredKey]: Expiration key.
  /// [purchaseIDKey]: Purchase ID key.
  /// [platformKey]: Platform key.
  /// [existOrderId]: Callback that returns True if the order id exists.
  const SubscribeOptions({
    this.data = const [],
    // this.task,
    // this.existOrderId,
    this.userIDKey = "user",
    this.expiryDateKey = "expiredTime",
    this.renewDuration = const Duration(hours: 2),
    this.purchaseIDKey = "purchaseId",
    this.tokenKey = "token",
    this.expiredKey = "expired",
    this.productIDKey = "productId",
    this.packageNameKey = "packageName",
    this.orderIDKey = "orderId",
    this.platformKey = "platform",
  });

  /// Collection that stores log data for subscriptions.
  final List<Map<String, dynamic>> data;

  // /// Asynchronous data for the collection that contains the subscription log data.
  // final Future<List<Map<String, dynamic>>>? task;

  // /// Expiration date key.
  final String expiryDateKey;

  /// The time to start the update.
  final Duration renewDuration;

  /// User ID key
  final String userIDKey;

  /// Token key.
  final String tokenKey;

  /// Package name key.
  final String packageNameKey;

  /// Order ID key.
  final String orderIDKey;

  /// Product ID key.
  final String productIDKey;

  /// Platform key.
  final String platformKey;

  /// Purchase ID key.
  final String purchaseIDKey;

  /// Callback that returns True if the order id exists.
  // final Future<bool> Function(String orderId)? existOrderId;

  /// Expiration key.
  final String expiredKey;
}
