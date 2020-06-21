part of masamune.purchase;

/// Class for managing billing process.
///
/// Initialize by first executing [initialize()].
///
/// Then purchasing item by executing [purchase()].
class PurchaseCore extends TaskCollection<PurchaseProduct> {
  final Future<bool> Function(PurchaseDetails purchase, PurchaseProduct product)
      _onVerify;
  final Future Function(PurchaseDetails purchase, PurchaseProduct product)
      _onDeliver;
  final bool _autoConsumeOnAndroid;

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
  static bool _isInitialized;

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
  static Future<PurchaseCore> initialize(
      {Iterable<PurchaseProduct> products,
      Future<bool> onPrepare(),
      Future<bool> onVerify(PurchaseDetails purchase, PurchaseProduct product),
      Future onDeliver(PurchaseDetails purchase, PurchaseProduct product),
      Duration timeout = Const.timeout,
      bool autoConsumeOnAndroid = true}) {
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
        autoConsumeOnAndroid: autoConsumeOnAndroid);
    collection._initializeProcess(timeout: timeout, onPrepare: onPrepare);
    return collection.future;
  }

  PurchaseCore._(
      {String path,
      Iterable<PurchaseProduct> children,
      Future<bool> onVerify(PurchaseDetails purchase, PurchaseProduct product),
      Future onDeliver(PurchaseDetails purchase, PurchaseProduct product),
      bool autoConsumeOnAndroid = true})
      : this._onDeliver = onDeliver,
        this._onVerify = onVerify,
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
        Log.msg("Purchase update.");
        try {
          purchaseDetailsList?.forEach((purchase) async {
            PurchaseProduct product = this.findByPurchase(purchase);
            if (purchase.status != PurchaseStatus.pending) {
              if (purchase.status == PurchaseStatus.error) {
                Log.error(purchase.error);
                return;
              } else if (purchase.status == PurchaseStatus.purchased) {
                if (this._onVerify != null &&
                    await this._onVerify(purchase, product)) {
                  if (this._onDeliver != null)
                    await this._onDeliver(purchase, product);
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
      final QueryPurchaseDetailsResponse purchaseResponse =
          await _connection.queryPastPurchases().timeout(timeout);
      if (purchaseResponse.error != null) {
        this.error(
            "Failed to load past purchases: ${purchaseResponse.error.message}");
        return;
      }
      for (PurchaseDetails purchase in purchaseResponse.pastPurchases) {
        if (purchase.status != PurchaseStatus.pending) continue;
        PurchaseProduct product = this.findByPurchase(purchase);
        if (product == null) continue;
        if (this._onVerify != null &&
            !await this._onVerify(purchase, product).timeout(timeout)) continue;
        if (this._onDeliver != null)
          await this._onDeliver(purchase, product).timeout(timeout);
      }
      _isInitialized = true;
      this.done();
    } on TimeoutException catch (e) {
      this.timeout(e.toString());
    } catch (e) {
      this.error(e.toString());
    }
  }

  /// Process the purchase.
  ///
  /// You specify the item ID in[id], the billing process will start.
  ///
  /// [id]: Item ID.
  /// [applicationUserName]: Application user name.
  /// [sandboxTesting]: True for sandbox environment.
  static Future<PurchaseCore> purchase(String id,
      {String applicationUserName, bool sandboxTesting = false}) {
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
        sandboxTesting: sandboxTesting);
    return collection.future;
  }

  void _purchaseProcess(
      {String id,
      String applicationUserName,
      bool sandboxTesting = false}) async {
    try {
      this.init();
      PurchaseProduct product = this.data[id];
      PurchaseParam purchaseParam = PurchaseParam(
          productDetails: product.data,
          applicationUserName: applicationUserName,
          sandboxTesting: sandboxTesting);
      if (product.type == ProductType.consumable) {
        await _connection.buyConsumable(
            purchaseParam: purchaseParam,
            autoConsume: this._autoConsumeOnAndroid || Config.isIOS);
      } else {
        await _connection.buyNonConsumable(purchaseParam: purchaseParam);
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
}