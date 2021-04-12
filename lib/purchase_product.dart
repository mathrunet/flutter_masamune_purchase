part of masamune_purchase;

/// Define the billing item.
///
/// Pass this object to [PurchaseCore.initialize()] to
/// get the billing item details from the server.
///
/// By defining [onDeliver], processing at the time of billing can be added.
class PurchaseProduct {
  /// Define the billing item.
  ///
  /// Pass this object to [PurchaseCore.initialize()] to
  /// get the billing item details from the server.
  ///
  /// By defining [onDeliver], processing at the time of billing can be added.
  ///
  /// [id]: Item ID.
  /// [type]: Item type.
  /// [value]: Item value.
  /// [targetPath]: Target path.
  /// [isEnabled]: Check out if non-consumption items and subscriptions are valid.
  /// [isRestoreTransaction]: Callback to restore billing.
  /// [onDeliver]: Processing at the time of billing.
  PurchaseProduct({
    required this.id,
    this.type = ProductType.consumable,
    this.value = 0,
    this.targetPath,
    this.subscriptionData,
    this.isEnabledListener,
    this.isRestoreTransaction,
    this.onDeliver,
  }) : assert(id.isNotEmpty, "The id is empty.");

  void _setInternal(ProductDetails details) => _productDetails = details;

  ProductDetails? _productDetails;

  final String id;

  /// Product type.
  final ProductType type;

  /// Product value.
  final double value;

  /// Target path.
  final String? targetPath;

  /// Callback to restore billing.
  ///
  /// True to restore billing.
  ///
  /// [subscriptionChecker] stores the callback that checks by passing the document for subscription.
  final Future<bool> Function(PurchaseDetails purchase,
          bool Function(Map<String, dynamic> document) subscriptionChecker)?
      isRestoreTransaction;

  /// Check out if non-consumption items and subscriptions are valid.
  ///
  /// If true, billing is enabled.
  ///
  /// [subscriptionChecker] stores the callback that checks by passing the document for subscription.
  final ValueNotifier<bool>? Function(
          PurchaseProduct product,
          SubscribeOptions subscribeOptions,
          bool Function(Map<String, dynamic> document) subscriptionChecker)?
      isEnabledListener;

  /// Callback for delivering billing items.
  final Future<void> Function(PurchaseDetails purchase, PurchaseProduct product,
      PurchaseModel core)? onDeliver;

  /// Get the data to be added at the time of subscription.
  final Future<Map<String, dynamic>?> Function(
      PurchaseDetails purchase, PurchaseModel core)? subscriptionData;

  /// Check out if non-consumption items and subscriptions are valid.
  ///
  /// If true, billing is enabled.
  bool get enabled =>
      type == ProductType.consumable || (_enabledValueNotifier?.value ?? false);

  // ignore: cancel_subscriptions
  ValueNotifier<bool>? _enabledValueNotifier;
  ChangeNotifierProvider<ValueNotifier<bool>>? _enabledValueNotifierProvider;

  /// Product Id.
  String get productId => _productDetails?.id ?? id;

  /// The name of the item.
  String get productName => _productDetails?.title ?? "";

  /// Item description.
  String get productDescription => _productDetails?.description ?? "";

  /// The price of the item.
  String get productPrice => _productDetails?.price ?? "";
}
