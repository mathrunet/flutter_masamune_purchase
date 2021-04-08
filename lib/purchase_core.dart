part of masamune_purchase;

class PurchaseCore {
  PurchaseCore._();

  static PurchaseModel get _purchase {
    return readProvider(purchaseModelProvider);
  }

  /// Class for managing billing process.
  ///
  /// Initialize by first executing [initialize()].
  ///
  /// Then purchasing item by executing [purchase()].
  ///
  /// [products]: Billing item definition.
  /// [onPrepare]: Callback before billing.
  /// [onVerify]: Callback for verification at the time of billing.
  /// [onDeliver]: Processing at the time of billing.
  /// [onSubscribe]: Subscription start processing.
  /// [onUnlock]: Purchase processing of non-consumable data.
  /// [onCheckSubscription]: Callback for initial check of subscription.
  /// [subscribeOptions]: The subscribed options.
  /// [timeout]: Timeout settings.
  /// [userId]: User ID.
  /// [androidRefreshToken]: Refresh Token for Android.
  /// [androidVerifierOptions]: Validation option for Android.
  /// [iosVerifierOptions]: Validation option for IOS.
  /// [deliverOptions]: Options for distributing billing items.
  static Future<PurchaseModel> initialize(
          {required List<PurchaseProduct> products,
          Future<bool> Function()? onPrepare,
          Future<bool> Function(PurchaseDetails purchase,
                  PurchaseProduct product, PurchaseModel core)?
              onVerify,
          Future<void> Function(PurchaseDetails purchase,
                  PurchaseProduct product, PurchaseModel core)?
              onSubscribe,
          Future<void> Function(PurchaseDetails purchase,
                  PurchaseProduct product, PurchaseModel core)?
              onUnlock,
          Future<void> Function(PurchaseDetails purchase,
                  PurchaseProduct product, PurchaseModel core)?
              onDeliver,
          Future<void> Function(PurchaseModel core)? onCheckSubscription,
          SubscribeOptions subscribeOptions = const SubscribeOptions(),
          Duration timeout = const Duration(seconds: 30),
          bool autoConsumeOnAndroid = true,
          String? androidRefreshToken,
          String? userId,
          AndroidVerifierOptions androidVerifierOptions =
              const AndroidVerifierOptions(),
          IOSVerifierOptions iosVerifierOptions = const IOSVerifierOptions(),
          DeliverOptions deliverOptions = const DeliverOptions()}) =>
      _purchase.initialize(
        products: products,
        onPrepare: onPrepare,
        onVerify: onVerify,
        onSubscribe: onSubscribe,
        onUnlock: onUnlock,
        onDeliver: onDeliver,
        onCheckSubscription: onCheckSubscription,
        subscribeOptions: subscribeOptions,
        timeout: timeout,
        autoConsumeOnAndroid: autoConsumeOnAndroid,
        androidRefreshToken: androidRefreshToken,
        userId: userId,
        androidVerifierOptions: androidVerifierOptions,
        iosVerifierOptions: iosVerifierOptions,
        deliverOptions: deliverOptions,
      );

  /// Restore purchase.
  ///
  /// Please use it manually or immediately after user registration.
  ///
  /// [timeout]: Timeout settings.
  static Future<PurchaseModel> restore(
          {Duration timeout = const Duration(seconds: 30)}) =>
      _purchase.restore(timeout: timeout);

  /// Consume all purchased items.
  ///
  /// Please use it manually or immediately after user registration.
  ///
  /// [productId]: Product ID to consume.
  /// [timeout]: Timeout settings.
  static Future<PurchaseModel> consume(
          {required String productId,
          Duration timeout = const Duration(seconds: 30)}) =>
      _purchase.consume(
        productId: productId,
        timeout: timeout,
      );

  /// Process the purchase.
  ///
  /// You specify the item ID in [id], the billing process will start.
  ///
  /// [id]: Item ID.
  /// [applicationUserName]: Application user name.
  /// [sandboxTesting]: True for sandbox environment.
  /// [timeout]: Timeout settings.
  static Future<PurchaseModel> purchase(String id,
          {String? applicationUserName,
          bool sandboxTesting = false,
          Duration timeout = const Duration(seconds: 30)}) =>
      _purchase.purchase(
        id,
        applicationUserName: applicationUserName,
        timeout: timeout,
        sandboxTesting: sandboxTesting,
      );

  /// Find the [PurchaseProduct] from [ProductId].
  ///
  /// [productId]: Product Id.
  static PurchaseProduct? getProduct(String productId) =>
      _purchase.getProduct(productId);

  /// Check out if non-consumption items and subscriptions are valid.
  ///
  /// If true, billing is enabled.
  ///
  /// [productId]: Product ID to check.
  static bool enabled(String productId) => _purchase.enabled(productId);

  static Stream<bool> enabledStream(String productId) =>
      _purchase.enabledStream(productId);

  static StreamProvider<bool> enabledStreamProvider(String productId) =>
      _purchase.enabledStreamProvider(productId);

  /// Run in the [main] method before executing with [initialize].
  static void enablePendingPurchases() {
    InAppPurchaseConnection.enablePendingPurchases();
  }

  /// True if the billing system has been initialized.
  static bool get isInitialized => _purchase._isInitialized;

  /// True if restored.
  static bool get isRestored => _purchase.isRestored;

  /// Find the [PurchaseProduct] from [ProductId].
  ///
  /// [productId]: Product Id.
  static PurchaseProduct? findById(String productId) =>
      _purchase.findById(productId);

  /// Find the [PurchaseProduct] from [PurchaseDetails].
  ///
  /// [details]: PurchaseDetails.
  static PurchaseProduct? findByPurchase(PurchaseDetails details) =>
      _purchase.findByPurchase(details);

  /// Find the [PurchaseProduct] from [ProductDetails].
  ///
  /// [details]: ProductDetails.
  static PurchaseProduct? findByProduct(ProductDetails details) =>
      _purchase.findByProduct(details);

  /// Get the Authorization Code for Google OAuth.
  static Future<void> getAuthorizationCode() =>
      _purchase.getAuthorizationCode();

  /// Get Refresh Token for Google OAuth.
  ///
  /// Please get the authorization code first.
  ///
  /// [authorizationCode]: Authorization code.
  static Future<String?> getAndroidRefreshToken(String authorizationCode) =>
      _purchase.getAndroidRefreshToken(authorizationCode);
}
