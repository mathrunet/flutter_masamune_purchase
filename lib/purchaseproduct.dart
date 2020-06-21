part of masamune.purchase;

/// Define the billing item.
///
/// Pass this object to [PurchaseCore.initialize()] to
/// get the billing item details from the server.
///
/// By defining [onDeliver], processing at the time of billing can be added.
class PurchaseProduct extends Unit<ProductDetails> {
  /// Product type.
  final ProductType type;

  /// Callback for delivering billing items.
  final Future Function(PurchaseDetails purchase, PurchaseProduct product)
      onDeliver;

  /// Get the protocol of the path.
  @override
  String get protocol => "purchase";

  /// Process to create a new instance.
  ///
  /// Do not use from outside the class.
  ///
  /// [path]: Destination path.
  /// [isTemporary]: True if the data is temporary.
  @override
  T createInstance<T extends IClonable>(String path, bool isTemporary) =>
      PurchaseProduct._(path, this.type, this.onDeliver) as T;

  /// Define the billing item.
  ///
  /// Pass this object to [PurchaseCore.initialize()] to
  /// get the billing item details from the server.
  ///
  /// By defining [onDeliver], processing at the time of billing can be added.
  ///
  /// [id]: Item ID.
  /// [type]: Item type.
  /// [onDeliver]: Processing at the time of billing.
  factory PurchaseProduct(
      {String id,
      ProductType type = ProductType.consumable,
      Future onDeliver(PurchaseDetails purchase, PurchaseProduct product)}) {
    id = id?.applyTags();
    assert(isNotEmpty(id));
    assert(type != null);
    if (isEmpty(id)) {
      Log.error("The id is empty.");
      return null;
    }
    String path = "purchase://iap/$id";
    PurchaseProduct unit = PathMap.get<PurchaseProduct>(path);
    if (unit != null) return unit;
    return PurchaseProduct._(path, type, onDeliver);
  }
  PurchaseProduct._(String path, ProductType type,
      Future onDeliver(PurchaseDetails purchase, PurchaseProduct product))
      : this.type = type,
        this.onDeliver = onDeliver,
        super(path, isTemporary: false, group: 0, order: 10);
  void _setInternal(ProductDetails details) {
    this.setInternal(details);
  }

  /// Product Id.
  String get productId => this.data == null ? this.id : this.data.id;

  /// The name of the item.
  String get productName => this.data?.title;

  /// Item description.
  String get productDescription => this.data?.description;

  /// The price of the item.
  String get productPrice => this.data?.price;
}
