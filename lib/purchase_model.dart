part of masamune_purchase;

final purchaseModelProvider = ModelProvider((_) => PurchaseModel());

class PurchaseModel extends ValueModel<List<PurchaseProduct>> {
  PurchaseModel() : super([]);

  @override
  bool get notifyOnChangeValue => false;

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
  Future<PurchaseModel> initialize(
      {required List<PurchaseProduct> products,
      Future<bool> Function()? onPrepare,
      Future<bool> Function(PurchaseDetails purchase, PurchaseProduct product,
              PurchaseModel core)?
          onVerify,
      Future<void> Function(PurchaseDetails purchase, PurchaseProduct product,
              PurchaseModel core)?
          onSubscribe,
      Future<void> Function(PurchaseDetails purchase, PurchaseProduct product,
              PurchaseModel core)?
          onUnlock,
      Future<void> Function(PurchaseDetails purchase, PurchaseProduct product,
              PurchaseModel core)?
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
      DeliverOptions deliverOptions = const DeliverOptions()}) async {
    if (isInitialized) {
      return this;
    }
    assert(products.isNotEmpty, "The products is empty.");
    _onVerify = onVerify ?? NonePurchaseDelegate.verify;
    _onDeliver = onDeliver;
    _onSubscribe = onSubscribe;
    _onUnlock = onUnlock;
    _onCheckSubscription = onCheckSubscription;
    _autoConsumeOnAndroid = autoConsumeOnAndroid;
    this.userId = userId ?? "";
    this.androidRefreshToken = androidRefreshToken ?? "";
    this.subscribeOptions = subscribeOptions;
    this.iosVerifierOptions = iosVerifierOptions;
    this.androidVerifierOptions = androidVerifierOptions;
    value = products;
    await _initializeProcess(timeout, onPrepare);
    return this;
  }

  Future<void> _initializeProcess(
      Duration timeout, Future<bool> Function()? onPrepare) async {
    try {
      if (onPrepare != null) {
        if (!await onPrepare()) {
          throw Exception("Preparation failed.");
        }
      }
      final isAvailable = await connection.isAvailable().timeout(timeout);
      assert(isAvailable, "Billing function is not supported.");
      final productDetailResponse = await connection
          .queryProductDetails(
              value.mapAndRemoveEmpty((element) => element.productId).toSet())
          .timeout(timeout);
      if (productDetailResponse.error != null) {
        throw Exception("Error occurred loading the product: "
            "${productDetailResponse.error?.message}");
      }
      if (productDetailResponse.productDetails.isEmpty) {
        throw Exception("The product is empty.");
      }
      for (final tmp in productDetailResponse.productDetails) {
        final found = value.firstWhereOrNull((product) => product.id == tmp.id);
        if (found == null) {
          continue;
        }
        found._setInternal(tmp);
        debugPrint("Adding Product: ${tmp.title} (${tmp.id})");
      }
      _purchaseUpdateStreamSubscription =
          connection.purchaseUpdatedStream.listen((purchaseDetailsList) async {
        try {
          var done = false;
          for (final purchase in purchaseDetailsList) {
            final product = findByPurchase(purchase);
            if (product == null) {
              throw Exception("Product not found.");
            }
            if (purchase.status != PurchaseStatus.pending) {
              if (purchase.status == PurchaseStatus.error) {
                if (purchase.pendingCompletePurchase) {
                  await connection.completePurchase(purchase);
                }
                throw Exception(
                    "Purchase completed with error: ${purchase.productID}");
              } else if (purchase.status == PurchaseStatus.purchased) {
                if (_onVerify != null &&
                    await _onVerify!(purchase, product, this)) {
                  switch (product.type) {
                    case ProductType.consumable:
                      await _onDeliver?.call(purchase, product, this);
                      break;
                    case ProductType.nonConsumable:
                      await _onUnlock?.call(purchase, product, this);
                      break;
                    case ProductType.subscription:
                      await _onSubscribe?.call(purchase, product, this);
                      break;
                  }
                } else {
                  throw Exception(
                      "There is no method for purchase. Set up a method for purchasing.");
                }
              }
              if (Config.isAndroid) {
                if (!_autoConsumeOnAndroid &&
                    product.type == ProductType.consumable) {
                  await connection.consumePurchase(purchase);
                }
              }
              if (purchase.pendingCompletePurchase) {
                debugPrint("Purchase completed: ${purchase.productID}");
                await connection.completePurchase(purchase);
              }
              done = true;
            }
          }
          await _checkEnabledProcess();
          if (done) {
            streamController.sink.add(value);
            notifyListeners();
          }
        } catch (e) {
          rethrow;
        }
      }, onDone: () {
        dispose();
      }, onError: (error) {
        throw Exception(error.toString());
      });
      await _onCheckSubscription?.call(this);
      if (Config.isIOS) {
        final paymentWrapper = SKPaymentQueueWrapper();
        final transactions = await paymentWrapper.transactions();
        for (final transaction in transactions) {
          try {
            await paymentWrapper.finishTransaction(transaction);
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }
      await _checkEnabledProcess();
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Restore purchase.
  ///
  /// Please use it manually or immediately after user registration.
  ///
  /// [timeout]: Timeout settings.
  Future<PurchaseModel> restore(
      {Duration timeout = const Duration(seconds: 30)}) async {
    assert(isInitialized,
        "It has not been initialized. First, execute [initialize] to initialize.");
    await _restoreProcess(timeout);
    return this;
  }

  Future<void> _restoreProcess(Duration timeout) async {
    try {
      final purchaseResponse =
          await connection.queryPastPurchases().timeout(timeout);
      if (purchaseResponse.error != null) {
        throw Exception(
            "Failed to load past purchases: ${purchaseResponse.error?.message}");
      }
      for (final purchase in purchaseResponse.pastPurchases) {
        final product = findByPurchase(purchase);
        if (product == null || purchase.purchaseID.isEmpty) {
          continue;
        }
        if (purchase.status == PurchaseStatus.pending ||
            product.type == ProductType.consumable ||
            product.isRestoreTransaction == null ||
            (subscribeOptions.purchaseIDKey.isNotEmpty &&
                !await product.isRestoreTransaction!(
                  purchase,
                  (document) => _subscriptionCheckerOnPurchase(
                      purchase.purchaseID!, document),
                ))) {
          continue;
        }
        debugPrint(
            "Restore transaction: ${purchase.productID}/${purchase.purchaseID}");
        if (_onVerify != null &&
            !await _onVerify!(purchase, product, this).timeout(timeout)) {
          continue;
        }
        switch (product.type) {
          case ProductType.consumable:
            await _onDeliver?.call(purchase, product, this);
            break;
          case ProductType.nonConsumable:
            await _onUnlock?.call(purchase, product, this);
            break;
          case ProductType.subscription:
            await _onSubscribe?.call(purchase, product, this);
            break;
        }
        debugPrint("Restored transaction: ${purchase.productID}");
        _isRestored = true;
      }
      await _checkEnabledProcess();
      streamController.sink.add(value);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Consume all purchased items.
  ///
  /// Please use it manually or immediately after user registration.
  ///
  /// [productId]: Product ID to consume.
  /// [timeout]: Timeout settings.
  Future<PurchaseModel> consume(
      {required String productId,
      Duration timeout = const Duration(seconds: 30)}) async {
    assert(isInitialized,
        "It has not been initialized. First, execute [initialize] to initialize.");
    await _consumeProcess(productId, timeout);
    return this;
  }

  Future<void> _consumeProcess(String productId, Duration timeout) async {
    try {
      final purchaseResponse =
          await connection.queryPastPurchases().timeout(timeout);
      if (purchaseResponse.error != null) {
        throw Exception(
            "Failed to load past purchases: ${purchaseResponse.error?.message}");
      }
      for (final purchase in purchaseResponse.pastPurchases) {
        final product = findByPurchase(purchase);
        if (product == null) {
          continue;
        }
        if (product.type == ProductType.consumable) {
          continue;
        }
        if (productId.isNotEmpty && product.id != productId) {
          continue;
        }
        await connection.consumePurchase(purchase);
        debugPrint(
            "Consumed transaction: ${purchase.productID}/${purchase.purchaseID}");
      }
      streamController.sink.add(value);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Process the purchase.
  ///
  /// You specify the item ID in [id], the billing process will start.
  ///
  /// [id]: Item ID.
  /// [applicationUserName]: Application user name.
  /// [sandboxTesting]: True for sandbox environment.
  /// [timeout]: Timeout settings.
  Future<PurchaseModel> purchase(String id,
      {String? applicationUserName,
      bool sandboxTesting = false,
      Duration timeout = const Duration(seconds: 30)}) async {
    assert(id.isNotEmpty, "The id is empty.");
    assert(isInitialized,
        "It has not been initialized. First, execute [initialize] to initialize.");
    final product = value.firstWhereOrNull((product) => product.id == id);
    if (product == null || product._productDetails == null) {
      throw Exception("Product not found: $id");
    }
    await _purchaseProcess(
        id: id,
        product: product,
        applicationUserName: applicationUserName,
        sandboxTesting: sandboxTesting,
        timeout: timeout);
    return this;
  }

  Future<void> _purchaseProcess(
      {required String id,
      required PurchaseProduct product,
      String? applicationUserName,
      bool sandboxTesting = false,
      Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final purchaseParam = PurchaseParam(
        productDetails: product._productDetails!,
        applicationUserName: applicationUserName,
        sandboxTesting: sandboxTesting,
      );
      if (product.type == ProductType.consumable) {
        await connection
            .buyConsumable(
                purchaseParam: purchaseParam,
                autoConsume: _autoConsumeOnAndroid || Config.isIOS)
            .timeout(timeout);
      } else {
        await connection
            .buyNonConsumable(purchaseParam: purchaseParam)
            .timeout(timeout);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _checkEnabledProcess() async {
    try {
      if (value.isEmpty) {
        return;
      }
      for (final product in value) {
        if (product.isEnabled == null) {
          continue;
        }
        if (!await product.isEnabled!(
          product,
          subscribeOptions,
          (document) =>
              _subscriptionCheckerOnCheckingEnabled(product.id, document),
        )) {
          continue;
        }
        product._enabled = true;
      }
    } catch (e) {
      rethrow;
    }
  }

  bool _subscriptionCheckerOnPurchase(
      String purchaseId, Map<String, dynamic> data) {
    if (subscribeOptions.purchaseIDKey.isEmpty) {
      return false;
    }
    return data.get<String>(subscribeOptions.purchaseIDKey) == purchaseId;
  }

  bool _subscriptionCheckerOnCheckingEnabled(
      String productId, Map<String, dynamic> data) {
    if (subscribeOptions.productIDKey.isEmpty ||
        subscribeOptions.expiredKey.isEmpty) {
      return false;
    }
    return data.get<String>(subscribeOptions.productIDKey) == productId &&
        !data.get<bool>(subscribeOptions.expiredKey).def(false);
  }

  /// Find the [PurchaseProduct] from [ProductId].
  ///
  /// [productId]: Product Id.
  PurchaseProduct? getProduct(String productId) {
    assert(isInitialized,
        "It has not been initialized. First, execute [initialize] to initialize.");
    return findById(productId);
  }

  /// Check out if non-consumption items and subscriptions are valid.
  ///
  /// If true, billing is enabled.
  ///
  /// [productId]: Product ID to check.
  bool enabled(String productId) {
    assert(productId.isNotEmpty, "The products id is empty.");
    assert(isInitialized,
        "It has not been initialized. First, execute [initialize] to initialize.");
    final product = findById(productId);
    if (product == null) {
      throw Exception("The product is not found.");
    }
    return product.enabled;
  }

  @override
  void dispose() {
    super.dispose();
    _purchaseUpdateStreamSubscription?.cancel();
  }

  late final Future<bool> Function(PurchaseDetails purchase,
      PurchaseProduct product, PurchaseModel core)? _onVerify;
  late final Future Function(PurchaseDetails purchase, PurchaseProduct product,
      PurchaseModel core)? _onDeliver;
  late final Future Function(PurchaseDetails purchase, PurchaseProduct product,
      PurchaseModel core)? _onSubscribe;
  late final Future Function(PurchaseDetails purchase, PurchaseProduct product,
      PurchaseModel core)? _onUnlock;
  late final Future Function(PurchaseModel core)? _onCheckSubscription;
  late final bool _autoConsumeOnAndroid;

  /// User ID.
  late final String userId;

  /// Refresh token for Android.
  late final String androidRefreshToken;

  /// Options for subscription.
  late final SubscribeOptions subscribeOptions;

  /// Validation option for Android.
  late final AndroidVerifierOptions androidVerifierOptions;

  /// Validation option for IOS.
  late final IOSVerifierOptions iosVerifierOptions;

  /// Options for distributing billing items.
  late final DeliverOptions deliverOptions;

  StreamSubscription<List<PurchaseDetails>>? _purchaseUpdateStreamSubscription;

  InAppPurchaseConnection get connection {
    return InAppPurchaseConnection.instance;
  }

  /// True if the billing system has been initialized.
  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;

  /// True if restored.
  bool get isRestored => _isRestored;
  bool _isRestored = false;

  /// Find the [PurchaseProduct] from [ProductId].
  ///
  /// [productId]: Product Id.
  PurchaseProduct? findById(String productId) {
    assert(productId.isEmpty, "ID is empty.");
    return value.firstWhereOrNull((product) => product.id == productId);
  }

  /// Find the [PurchaseProduct] from [PurchaseDetails].
  ///
  /// [details]: PurchaseDetails.
  PurchaseProduct? findByPurchase(PurchaseDetails details) {
    return value.firstWhereOrNull((product) => product.id == details.productID);
  }

  /// Find the [PurchaseProduct] from [ProductDetails].
  ///
  /// [details]: ProductDetails.
  PurchaseProduct? findByProduct(ProductDetails details) {
    return value.firstWhereOrNull((product) => product.id == details.id);
  }

  /// Get the Authorization Code for Google OAuth.
  Future<void> getAuthorizationCode() async {
    if (!Config.isAndroid) {
      return;
    }
    if (androidVerifierOptions.clientId.isEmpty) {
      return;
    }
    await openURL(
      "https://accounts.google.com/o/oauth2/auth"
      "?scope=https://www.googleapis.com/auth/androidpublisher"
      "&response_type=code&access_type=offline"
      "&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
      "&client_id=${androidVerifierOptions.clientId}",
    );
  }

  /// Get Refresh Token for Google OAuth.
  ///
  /// Please get the authorization code first.
  ///
  /// [authorizationCode]: Authorization code.
  Future<String?> getAndroidRefreshToken(String authorizationCode) async {
    if (!Config.isAndroid) {
      return null;
    }
    if (androidVerifierOptions.clientId.isEmpty ||
        androidVerifierOptions.clientSecret.isEmpty ||
        authorizationCode.isEmpty) {
      return null;
    }
    final response = await post(
      Uri.parse("https://accounts.google.com/o/oauth2/token"),
      headers: {"content-type": "application/x-www-form-urlencoded"},
      body: {
        "grant_type": "authorization_code",
        "client_id": androidVerifierOptions.clientId,
        "client_secret": androidVerifierOptions.clientSecret,
        "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
        "access_type": "offline",
        "code": authorizationCode
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
          "Server Error: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
    }
    final map = jsonDecodeAsMap(response.body);
    if (map.isEmpty) {
      throw Exception(
          "Response is empty: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
    }
    return androidRefreshToken = map.get<String>("refresh_token").def("");
  }
}
