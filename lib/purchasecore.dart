part of masamune.purchase;

/// Class for managing billing process.
///
/// Initialize by first executing [initialize()].
///
/// Then purchasing item by executing [purchase()].
class PurchaseCore extends TaskCollection<PurchaseProduct> {
  final Future<bool> Function(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core)
      _onVerify;
  final Future Function(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core)
      _onDeliver;
  final Future Function(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core)
      _onSubscribe;
  final Future Function(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core)
      _onUnlock;
  final Future Function(PurchaseCore core) _onCheckSubscription;
  final bool _autoConsumeOnAndroid;

  /// User ID.
  final String userId;

  /// Refresh token for Android.
  String get androidRefreshToken => this._androidRefreshToken;
  String _androidRefreshToken;

  /// Options for subscription.
  final SubscribeOptions subscribeOptions;

  /// Validation option for Android.
  final AndroidVerifierOptions androidVerifierOptions;

  /// Validation option for IOS.
  final IOSVerifierOptions iosVerifierOptions;

  /// Options for distributing billing items.
  final DeliverOptions deliverOptions;

  /// Create a Completer that matches the class.
  ///
  /// Do not use from external class.
  @override
  Completer createCompleter() => Completer<PurchaseCore>();

  /// Process to create a new instance.
  ///
  /// Do not use from outside the class.
  ///
  /// [path]: Destination path.
  /// [isTemporary]: True if the data is temporary.
  @override
  T createInstance<T extends IClonable>(String path, bool isTemporary) {
    throw UnimplementedError();
  }

  /// Get the protocol of the path.
  @override
  String get protocol => "purchase";
  static InAppPurchaseConnection get _connection {
    if (__connection == null) __connection = InAppPurchaseConnection.instance;
    return __connection;
  }

  static InAppPurchaseConnection __connection;
  StreamSubscription<List<PurchaseDetails>> _stream;

  /// True if the billing system has been initialized.
  static bool get isInitialized => _isInitialized;
  static bool _isInitialized = false;

  /// True if restored.
  static bool get isRestored => _isRestored;
  static bool _isRestored = false;

  /// Class for managing billing process.
  ///
  /// Initialize by first executing [initialize()].
  ///
  /// Then purchasing item by executing [purchase()].
  factory PurchaseCore() {
    PurchaseCore collection = PathMap.get<PurchaseCore>(_systemPath);
    if (collection != null) return collection;
    Log.warning(
        "No data was found from the pathmap. Please execute [initialize()] first.");
    return null;
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
  static Future<PurchaseCore> initialize(
      {Iterable<PurchaseProduct> products,
      Future<bool> onPrepare(),
      Future<bool> onVerify(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core),
      Future onSubscribe(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core),
      Future onUnlock(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core),
      Future onDeliver(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core),
      Future onCheckSubscription(PurchaseCore core),
      SubscribeOptions subscribeOptions,
      Duration timeout = Const.timeout,
      bool autoConsumeOnAndroid = true,
      String androidRefreshToken,
      String userId,
      AndroidVerifierOptions androidVerifierOptions,
      IOSVerifierOptions iosVerifierOptions,
      DeliverOptions deliverOptions}) {
    assert(products != null && products.length > 0);
    if (products == null || products.length <= 0) {
      Log.error("The products is empty.");
      return Future.delayed(Duration.zero);
    }
    PurchaseCore collection = PathMap.get<PurchaseCore>(_systemPath);
    if (collection != null) {
      if (products != null) collection._setInternal(products);
      return collection.future;
    }
    collection = PurchaseCore._(
        path: _systemPath,
        children: products,
        onDeliver: onDeliver,
        onVerify: onVerify,
        onSubscribe: onSubscribe,
        onUnlock: onUnlock,
        userId: userId,
        subscribeOptions: subscribeOptions,
        onCheckSubscription: onCheckSubscription,
        autoConsumeOnAndroid: autoConsumeOnAndroid,
        androidRefreshToken: androidRefreshToken,
        androidVerifierOptions: androidVerifierOptions,
        iosVerifierOptions: iosVerifierOptions,
        deliverOptions: deliverOptions);
    collection._initializeProcess(timeout: timeout, onPrepare: onPrepare);
    return collection.future;
  }

  PurchaseCore._(
      {String path,
      Iterable<PurchaseProduct> children,
      Future<bool> onVerify(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core),
      Future onDeliver(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core),
      Future onUnlock(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core),
      Future onSubscribe(
          PurchaseDetails purchase, PurchaseProduct product, PurchaseCore core),
      Future onCheckSubscription(PurchaseCore core),
      bool autoConsumeOnAndroid = true,
      String androidRefreshToken,
      this.userId,
      this.subscribeOptions,
      this.androidVerifierOptions,
      this.iosVerifierOptions,
      this.deliverOptions})
      : this._onDeliver = onDeliver,
        this._onVerify = onVerify,
        this._onSubscribe = onSubscribe,
        this._onUnlock = onUnlock,
        this._onCheckSubscription = onCheckSubscription,
        this._androidRefreshToken = androidRefreshToken,
        this._autoConsumeOnAndroid = autoConsumeOnAndroid,
        super(
            path: path,
            children: children,
            isTemporary: false,
            order: 10,
            group: -1);
  static const String _systemPath = "purchase://iap";
  void _setInternal(Iterable<PurchaseProduct> children) {
    if (children != null) {
      for (PurchaseProduct doc in children) {
        if (doc == null) continue;
        this.setInternal(doc);
      }
    }
  }

  void _initializeProcess({Duration timeout, Future<bool> onPrepare()}) async {
    try {
      if (_connection == null) __connection = InAppPurchaseConnection.instance;
      if (onPrepare != null) {
        if (!await onPrepare()) {
          this.error("Preparation failed.");
          return;
        }
      }
      final bool isAvailable = await _connection.isAvailable().timeout(timeout);
      if (!isAvailable) {
        this.error("Billing function is not supported.");
        return;
      }
      ProductDetailsResponse productDetailResponse = await _connection
          .queryProductDetails(
              this.mapAndRemoveEmpty((element) => element?.productId).toSet())
          .timeout(timeout);
      if (productDetailResponse.error != null) {
        this.error("Error occurred loading the product: "
            "${productDetailResponse.error.message}");
        return;
      }
      if (productDetailResponse.productDetails.isEmpty) {
        this.error("The product is empty.");
        return;
      }
      for (ProductDetails tmp in productDetailResponse.productDetails) {
        if (tmp == null || !this.data.containsKey(tmp.id)) continue;
        this.data[tmp.id]?._setInternal(tmp);
        Log.msg("Adding Product: ${tmp.title} (${tmp.id})");
      }
      this._stream =
          _connection.purchaseUpdatedStream.listen((purchaseDetailsList) {
        try {
          purchaseDetailsList?.forEach((purchase) async {
            PurchaseProduct product = this.findByPurchase(purchase);
            if (purchase.status != PurchaseStatus.pending) {
              if (purchase.status == PurchaseStatus.error) {
                Log.error(purchase.error);
                return;
              } else if (purchase.status == PurchaseStatus.purchased) {
                if (this._onVerify != null &&
                    await this._onVerify(purchase, product, this)) {
                  switch (product.type) {
                    case ProductType.consumable:
                      if (this._onDeliver != null)
                        await this._onDeliver(purchase, product, this);
                      break;
                    case ProductType.nonConsumable:
                      if (this._onUnlock != null)
                        await this._onUnlock(purchase, product, this);
                      break;
                    case ProductType.subscription:
                      if (this._onSubscribe != null)
                        await this._onSubscribe(purchase, product, this);
                      break;
                  }
                } else {
                  Log.error("The purchase failed.");
                  return;
                }
              }
              if (Config.isAndroid) {
                if (!this._autoConsumeOnAndroid &&
                    product.type == ProductType.consumable) {
                  await _connection.consumePurchase(purchase);
                }
              }
              if (purchase.pendingCompletePurchase) {
                Log.msg("Purchase completed: ${purchase.productID}");
                await _connection.completePurchase(purchase);
              }
            }
          });
        } catch (e) {
          Log.error(e.toString());
        }
      }, onDone: () {
        this.dispose();
      }, onError: (error) {
        this.error(error.toString());
        this.dispose();
      });
      if (this.subscribeOptions != null && this._onCheckSubscription != null) {
        await this._onCheckSubscription(this);
      }
      if (Config.isIOS) {
        SKPaymentQueueWrapper paymentWrapper = SKPaymentQueueWrapper();
        List<SKPaymentTransactionWrapper> transactions =
            await paymentWrapper.transactions();
        for (SKPaymentTransactionWrapper transaction in transactions) {
          try {
            await paymentWrapper.finishTransaction(transaction);
          } catch (e) {}
        }
      }
      _isInitialized = true;
      this.done();
    } on TimeoutException catch (e) {
      this.timeout(e.toString());
    } catch (e) {
      this.error(e.toString());
    }
  }

  /// Restore purchase.
  ///
  /// Please use it manually or immediately after user registration.
  ///
  /// [timeout]: Timeout settings.
  static Future<PurchaseCore> restore({Duration timeout = Const.timeout}) {
    PurchaseCore collection = PathMap.get<PurchaseCore>(_systemPath);
    if (collection == null || !isInitialized) {
      Log.error("It has not been initialized. "
          "First, execute [initialize] to initialize.");
      return Future.delayed(Duration.zero);
    }
    collection._restoreProcess(timeout);
    return collection.future;
  }

  void _restoreProcess(Duration timeout) async {
    try {
      this.init();
      final QueryPurchaseDetailsResponse purchaseResponse =
          await _connection.queryPastPurchases().timeout(timeout);
      if (purchaseResponse.error != null) {
        this.error(
            "Failed to load past purchases: ${purchaseResponse.error.message}");
        return;
      }
      for (PurchaseDetails purchase in purchaseResponse.pastPurchases) {
        PurchaseProduct product = this.findByPurchase(purchase);
        if (product == null) continue;
        if (purchase.status == PurchaseStatus.pending ||
            product.type == ProductType.consumable ||
            product.isRestoreTransaction == null ||
            !await product.isRestoreTransaction(
                purchase,
                (document) =>
                    document.getString(this.subscribeOptions.purchaseIDKey) ==
                    purchase.purchaseID)) continue;
        Log.msg(
            "Restore transaction: ${purchase.productID}/${purchase.purchaseID}");
        if (this._onVerify != null &&
            !await this._onVerify(purchase, product, this).timeout(timeout))
          continue;
        switch (product.type) {
          case ProductType.consumable:
            if (this._onDeliver != null)
              await this._onDeliver(purchase, product, this);
            break;
          case ProductType.nonConsumable:
            if (this._onUnlock != null)
              await this._onUnlock(purchase, product, this);
            break;
          case ProductType.subscription:
            if (this._onSubscribe != null)
              await this._onSubscribe(purchase, product, this);
            break;
        }
        Log.msg("Restored transaction: ${purchase.productID}");
        _isRestored = true;
      }
      this.done();
    } catch (e) {
      this.error(e.toString());
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
  static Future<PurchaseCore> purchase(String id,
      {String applicationUserName,
      bool sandboxTesting = false,
      Duration timeout = Const.timeout}) {
    assert(isNotEmpty(id));
    assert(isInitialized);
    PurchaseCore collection = PathMap.get<PurchaseCore>(_systemPath);
    if (collection == null || !isInitialized) {
      Log.error("It has not been initialized. "
          "First, execute [initialize] to initialize.");
      return Future.delayed(Duration.zero);
    }
    if (isEmpty(id)) {
      Log.error("The id is empty.");
      return Future.delayed(Duration.zero);
    }
    if (!collection.containsID(id)) {
      Log.error("Product not found: $id");
      return Future.delayed(Duration.zero);
    }
    collection._purchaseProcess(
        id: id,
        applicationUserName: applicationUserName,
        sandboxTesting: sandboxTesting,
        timeout: timeout);
    return collection.future;
  }

  void _purchaseProcess(
      {String id,
      String applicationUserName,
      bool sandboxTesting = false,
      Duration timeout = Const.timeout}) async {
    try {
      this.init();
      PurchaseProduct product = this.data[id];
      PurchaseParam purchaseParam = PurchaseParam(
          productDetails: product.data,
          applicationUserName: applicationUserName,
          sandboxTesting: sandboxTesting);
      if (product.type == ProductType.consumable) {
        await _connection
            .buyConsumable(
                purchaseParam: purchaseParam,
                autoConsume: this._autoConsumeOnAndroid || Config.isIOS)
            .timeout(timeout);
      } else {
        await _connection
            .buyNonConsumable(purchaseParam: purchaseParam)
            .timeout(timeout);
      }
      this.done();
    } catch (e) {
      this.error(e.toString());
    }
  }

  /// Find the [PurchaseProduct] from [PurchaseDetails].
  ///
  /// [details]: PurchaseDetails.
  PurchaseProduct findByPurchase(PurchaseDetails details) {
    if (details == null || !this.data.containsKey(details.productID))
      return null;
    return this.data[details.productID];
  }

  /// Find the [PurchaseProduct] from [ProductDetails].
  ///
  /// [details]: ProductDetails.
  PurchaseProduct findByProduct(ProductDetails details) {
    if (details == null || !this.data.containsKey(details.id)) return null;
    return this.data[details.id];
  }

  /// Destroys the object.
  ///
  /// Destroyed objects are not allowed.
  @override
  @mustCallSuper
  void dispose() {
    if (this._stream != null) this._stream.cancel();
    super.dispose();
  }

  /// Get the Authorization Code for Google OAuth.
  static Future getAuthorizationCode() async {
    if (!Config.isAndroid) return;
    PurchaseCore core = PurchaseCore();
    if (core == null) return;
    if (core.androidVerifierOptions == null ||
        isEmpty(core.androidVerifierOptions.clientId)) return;
    await openURL("https://accounts.google.com/o/oauth2/auth"
        "?scope=https://www.googleapis.com/auth/androidpublisher"
        "&response_type=code&access_type=offline"
        "&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
        "&client_id=${core.androidVerifierOptions.clientId}");
  }

  /// Get Refresh Token for Google OAuth.
  ///
  /// Please get the authorization code first.
  ///
  /// [authorizationCode]: Authorization code.
  static Future<String> getAndroidRefreshToken(String authorizationCode) async {
    if (!Config.isAndroid) return null;
    PurchaseCore core = PurchaseCore();
    if (core == null) return null;
    if (core.androidVerifierOptions == null ||
        isEmpty(core.androidVerifierOptions.clientId) ||
        isEmpty(core.androidVerifierOptions.clientSecret) ||
        isEmpty(authorizationCode)) return null;
    Response response =
        await post("https://accounts.google.com/o/oauth2/token", headers: {
      "content-type": "application/x-www-form-urlencoded"
    }, body: {
      "grant_type": "authorization_code",
      "client_id": core.androidVerifierOptions.clientId,
      "client_secret": core.androidVerifierOptions.clientSecret,
      "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
      "access_type": "offline",
      "code": authorizationCode
    });
    if (response.statusCode != 200) return null;
    Map<String, dynamic> map = Json.decodeAsMap(response.body);
    if (map == null) return null;
    return core._androidRefreshToken = map["refresh_token"];
  }
}
