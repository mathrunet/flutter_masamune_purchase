part of masamune.purchase;

/// Class for managing billing process.
///
/// Initialize by first executing [initialize()].
///
/// Then purchasing item by executing [purchase()].
class ClientPurchaseDelegate {
  /// Get data for purchased subscriptions.
  ///
  /// [purchase]: PurchaseDetails.
  /// [product]: The purchased product.
  /// [core]: Purchase Core instance.
  static Future<Map<String, dynamic>> getSubscribedInfo(
      PurchaseDetails purchase,
      PurchaseProduct product,
      PurchaseCore core) async {
    if (Config.isAndroid) {
      if (core.androidVerifierOptions == null ||
          isEmpty(core.androidRefreshToken) ||
          isEmpty(core.androidVerifierOptions.clientId) ||
          isEmpty(core.androidVerifierOptions.clientSecret) ||
          isEmpty(core.androidVerifierOptions.publicKey)) return null;
      if (isEmpty(core.subscribeOptions.expiryDateKey) ||
          isEmpty(core.subscribeOptions.tokenKey) ||
          isEmpty(core.subscribeOptions.orderIDKey) ||
          isEmpty(core.subscribeOptions.packageNameKey) ||
          isEmpty(core.subscribeOptions.productIDKey) ||
          isEmpty(core.subscribeOptions.userIDKey)) return null;
      Response response =
          await post("https://accounts.google.com/o/oauth2/token", headers: {
        "content-type": "application/x-www-form-urlencoded"
      }, body: {
        "grant_type": "refresh_token",
        "client_id": core.androidVerifierOptions.clientId,
        "client_secret": core.androidVerifierOptions.clientSecret,
        "refresh_token": core.androidRefreshToken
      });
      if (response.statusCode != 200) return null;
      Map<String, dynamic> map = Json.decodeAsMap(response.body);
      if (map == null) return null;
      String accessToken = map["access_token"];
      if (isEmpty(accessToken)) return null;
      response = await get(
          "https://www.googleapis.com/androidpublisher/v3/applications/"
          "${purchase.billingClientPurchase.packageName}/purchases/subscriptions/"
          "${purchase.productID}/tokens/"
          "${purchase.billingClientPurchase.purchaseToken}?access_token=$accessToken",
          headers: {"content-type": "application/json"});
      if (response.statusCode != 200) return null;
      map = Json.decodeAsMap(response.body);
      if (map == null) return null;
      Map<String, dynamic> res = MapPool.get();
      for (MapEntry<String, dynamic> tmp in map.entries) {
        if (isEmpty(tmp.key) || tmp.value == null) continue;
        if (tmp.value is String) {
          int i = int.tryParse(tmp.value);
          if (i == null)
            res[tmp.key] = tmp.value;
          else
            res[tmp.key] = i;
        } else {
          res[tmp.key] = tmp.value;
        }
      }
      res[core.subscribeOptions.expiryDateKey] = int.tryParse(map["expiryTimeMillis"]);
      res[core.subscribeOptions.tokenKey] =
          purchase.billingClientPurchase.purchaseToken;
      res[core.subscribeOptions.productIDKey] = purchase.productID;
      res[core.subscribeOptions.orderIDKey] = map["orderId"];
      res[core.subscribeOptions.packageNameKey] =
          purchase.billingClientPurchase.packageName;
      res[core.subscribeOptions.platformKey] = "Android";
      if (isNotEmpty(core.userId))
        res[core.subscribeOptions.userIDKey] = core.userId;
      return res;
    } else if (Config.isIOS) {
      if (core.iosVerifierOptions == null ||
          isEmpty(core.iosVerifierOptions.sharedSecret)) return null;
      if (isEmpty(core.subscribeOptions.expiryDateKey) ||
          isEmpty(core.subscribeOptions.tokenKey) ||
          isEmpty(core.subscribeOptions.orderIDKey) ||
          isEmpty(core.subscribeOptions.packageNameKey) ||
          isEmpty(core.subscribeOptions.productIDKey) ||
          isEmpty(core.subscribeOptions.userIDKey)) return null;
      Response response = await post(
          "https://buy.itunes.apple.com/verifyReceipt",
          headers: {
            "content-type": "application/json",
            "accept": "application/json"
          },
          body: Json.encode({
            "receipt-data": purchase.verificationData.serverVerificationData,
            "password": core.iosVerifierOptions.sharedSecret,
            "exclude-old-transactions": true
          }));
      if (response.statusCode != 200) return null;
      Map<String, dynamic> map = Json.decodeAsMap(response.body);
      if (map == null) return null;
      int status = map["status"];
      if (status == 21007 || status == 21008) {
        response = await post("https://sandbox.itunes.apple.com/verifyReceipt",
            headers: {
              "content-type": "application/json",
              "accept": "application/json"
            },
            body: Json.encode({
              "receipt-data": purchase.verificationData.serverVerificationData,
              "password": core.iosVerifierOptions.sharedSecret,
              "exclude-old-transactions": true
            }));
        if (response.statusCode != 200) return null;
        map = Json.decodeAsMap(response.body);
        if (map == null || map["status"] != 0) return null;
      } else if (status != 0) {
        return null;
      }
      Map<String, dynamic> res = MapPool.get();
      if (!map.containsKey("latest_receipt_info") ||
          map["latest_receipt_info"]?.first == null) return null;
      for (MapEntry<String, dynamic> tmp
          in map["latest_receipt_info"].first.entries) {
        if (isEmpty(tmp.key) || tmp.value == null) continue;
        if (tmp.value is String) {
          int i = int.tryParse(tmp.value);
          if (i == null)
            res[tmp.key] = tmp.value;
          else
            res[tmp.key] = i;
        } else {
          res[tmp.key] = tmp.value;
        }
      }
      if (!map["latest_receipt_info"].first.containsKey("expires_date_ms") ||
          !map["latest_receipt_info"].first.containsKey("transaction_id") ||
          !map.containsKey("receipt") ||
          !map["receipt"].containsKey("bundle_id")) return null;
      res[core.subscribeOptions.expiryDateKey] =
          int.tryParse( map["latest_receipt_info"].first["expires_date_ms"] );
      res[core.subscribeOptions.tokenKey] =
          purchase.verificationData.serverVerificationData;
      res[core.subscribeOptions.productIDKey] = purchase.productID;
      res[core.subscribeOptions.orderIDKey] =
          map["latest_receipt_info"].first["transaction_id"];
      res[core.subscribeOptions.packageNameKey] = map["receipt"]["bundle_id"];
      res[core.subscribeOptions.platformKey] = "IOS";
      if (isNotEmpty(core.userId))
        res[core.subscribeOptions.userIDKey] = core.userId;
      return res;
    }
    return null;
  }

  /// Monitor subscription status, update, delete, etc.
  ///
  /// [core]: PurchaseCore object.
  static Future checkSubscription(PurchaseCore core) async {
    if (core.androidVerifierOptions == null ||
        isEmpty(core.androidRefreshToken) ||
        isEmpty(core.androidVerifierOptions.clientId) ||
        isEmpty(core.androidVerifierOptions.clientSecret) ||
        isEmpty(core.androidVerifierOptions.publicKey)) return;
    if (core.iosVerifierOptions == null ||
        isEmpty(core.iosVerifierOptions.sharedSecret)) return;
    if (isEmpty(core.subscribeOptions.expiryDateKey) ||
        isEmpty(core.subscribeOptions.tokenKey) ||
        isEmpty(core.subscribeOptions.orderIDKey) ||
        isEmpty(core.subscribeOptions.platformKey) ||
        isEmpty(core.subscribeOptions.packageNameKey) ||
        isEmpty(core.subscribeOptions.productIDKey) ||
        isEmpty(core.subscribeOptions.userIDKey) ||
        isEmpty(core.subscribeOptions.expiredKey)) return;
    if (core.subscribeOptions.data == null &&
        core.subscribeOptions.task == null) return;
    IDataCollection data = core.subscribeOptions.data;
    if (core.subscribeOptions.task != null) {
      data = await core.subscribeOptions.task;
    }
    List<IDataDocument> updated = ListPool.get();
    for (IDataDocument document in data) {
      if (document == null ||
          !document.containsKey(core.subscribeOptions.expiryDateKey) ||
          !document.containsKey(core.subscribeOptions.tokenKey) ||
          !document.containsKey(core.subscribeOptions.platformKey) ||
          !document.containsKey(core.subscribeOptions.orderIDKey) ||
          !document.containsKey(core.subscribeOptions.packageNameKey) ||
          !document.containsKey(core.subscribeOptions.productIDKey)) continue;
      if (document.getBool(core.subscribeOptions.expiredKey)) continue;
      int expiryDate = document.getInt(core.subscribeOptions.expiryDateKey);
      if (expiryDate - DateTime.now().toUtc().millisecondsSinceEpoch >
          core.subscribeOptions.renewDuration.inMilliseconds) continue;
      Log.msg(
          "Updating subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
      updated.add(document);
    }
    if (updated.length <= 0) return;
    Response response =
        await post("https://accounts.google.com/o/oauth2/token", headers: {
      "content-type": "application/x-www-form-urlencoded"
    }, body: {
      "grant_type": "refresh_token",
      "client_id": core.androidVerifierOptions.clientId,
      "client_secret": core.androidVerifierOptions.clientSecret,
      "refresh_token": core.androidRefreshToken
    });
    if (response.statusCode != 200) return;
    Map<String, dynamic> map = Json.decodeAsMap(response.body);
    if (map == null) return;
    String accessToken = map["access_token"];
    if (isEmpty(accessToken)) return;
    for (IDataDocument document in updated) {
      if (document == null) continue;
      String platform = document.getString(core.subscribeOptions.platformKey);
      String token = document.getString(core.subscribeOptions.tokenKey);
      switch(platform){
        case "Android":
        String packageName =
            document.getString(core.subscribeOptions.packageNameKey);
        String productId =
            document.getString(core.subscribeOptions.productIDKey);
        if (isEmpty(token) || isEmpty(packageName) || isEmpty(productId))
          continue;
        response = await get(
            "https://www.googleapis.com/androidpublisher/v3/applications/"
            "$packageName/purchases/subscriptions/"
            "$productId/tokens/"
            "$token?access_token=$accessToken",
            headers: {"content-type": "application/json"});
        if (response.statusCode != 200) return false;
        map = Json.decodeAsMap(response.body);
        int expiryTimeMillis = int.tryParse(map["expiryTimeMillis"]);
        String orderId = map["orderId"];
        if (expiryTimeMillis < DateTime.now().toUtc().millisecondsSinceEpoch) {
          document[core.subscribeOptions.expiredKey] = true;
          await document.save();
          Log.msg(
              "Expired subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
        } else if (isNotEmpty(orderId) &&
            (core.subscribeOptions.existOrderId == null ||
                !await core.subscribeOptions.existOrderId(orderId))) {
          for (MapEntry<String, dynamic> tmp in map.entries) {
            if (isEmpty(tmp.key) || tmp.value == null) continue;
            if (tmp.value is String) {
              int i = int.tryParse(tmp.value);
              if (i == null)
                document[tmp.key] = tmp.value;
              else
                document[tmp.key] = i;
            } else {
              document[tmp.key] = tmp.value;
            }
          }
          document[core.subscribeOptions.expiryDateKey] = int.tryParse(map["expiryTimeMillis"]);
          document[core.subscribeOptions.orderIDKey] = map["orderId"];
          await document.save();
          Log.msg(
              "Updated subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
        }
        break;
        case "IOS":
        if (isEmpty(token)) continue;
        Response response = await post(
            "https://buy.itunes.apple.com/verifyReceipt",
            headers: {
              "content-type": "application/json",
              "accept": "application/json"
            },
            body: Json.encode({
              "receipt-data": token,
              "password": core.iosVerifierOptions.sharedSecret,
              "exclude-old-transactions": true
            }));
        if (response.statusCode != 200) return null;
        Map<String, dynamic> map = Json.decodeAsMap(response.body);
        if (map == null) return null;
        int status = map["status"];
        if (status == 21007 || status == 21008) {
          response = await post(
              "https://sandbox.itunes.apple.com/verifyReceipt",
              headers: {
                "content-type": "application/json",
                "accept": "application/json"
              },
              body: Json.encode({
                "receipt-data": token,
                "password": core.iosVerifierOptions.sharedSecret,
                "exclude-old-transactions": true
              }));
          if (response.statusCode != 200) return null;
          map = Json.decodeAsMap(response.body);
          if (map == null || map["status"] != 0) return null;
        }
        int expiryTimeMillis =
            int.tryParse(map["latest_receipt_info"].first["expires_date_ms"]);
        if (expiryTimeMillis == null) continue;
        String orderId = map["latest_receipt_info"].first["transaction_id"];
        if (map.containsKey("pending_renewal_info") &&
            map["pending_renewal_info"].any((info) {
              if (!info.containsKey("is_in_billing_retry_period")) return false;
              return info["is_in_billing_retry_period"] == "1";
            })) {
          document[core.subscribeOptions.expiryDateKey] = document.getInt(
                  core.subscribeOptions.expiryDateKey,
                  DateTime.now().toUtc().millisecondsSinceEpoch) +
              Duration(hours: 2).inMilliseconds;
          await document.save();
          Log.msg(
              "Postponing expiration of subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
        } else if (map.containsKey("pending_renewal_info") &&
            expiryTimeMillis < DateTime.now().toUtc().millisecondsSinceEpoch &&
            map["pending_renewal_info"].every((info) {
              if (!info.containsKey("is_in_billing_retry_period") ||
                  !info.containsKey("auto_renew_status")) return true;
              return info["is_in_billing_retry_period"] != "1" &&
                  info["auto_renew_status"] != "1";
            })) {
          document[core.subscribeOptions.expiredKey] = true;
          await document.save();
          Log.msg(
              "Expired subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
        } else if (isNotEmpty(orderId) &&
            (core.subscribeOptions.existOrderId == null ||
                !await core.subscribeOptions.existOrderId(orderId))) {
          for (MapEntry<String, dynamic> tmp
              in map["latest_receipt_info"].first.entries) {
            if (isEmpty(tmp.key) || tmp.value == null) continue;
            if (tmp.value is String) {
              int i = int.tryParse(tmp.value);
              if (i == null)
                document[tmp.key] = tmp.value;
              else
                document[tmp.key] = i;
            } else {
              document[tmp.key] = tmp.value;
            }
          }
          document[core.subscribeOptions.expiryDateKey] =
              int.tryParse( map["latest_receipt_info"].first["expires_date_ms"] );
          document[core.subscribeOptions.orderIDKey] =
              map["latest_receipt_info"].first["transaction_id"];
          await document.save();
          Log.msg(
              "Updated subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
        }
        break;
      }
    }
  }

  /// [PurchaseCore] is used as a callback for [onVerify] of [PurchaseCore].
  ///
  /// The signature is verified and the receipt is verified locally.
  ///
  /// [purchase]: PurchaseDetails.
  /// [product]: The purchased product.
  /// [core]: Purchase Core instance.
  static Future<bool> verify(PurchaseDetails purchase, PurchaseProduct product,
      PurchaseCore core) async {
    if (Config.isAndroid) {
      if (core.androidVerifierOptions == null ||
          isEmpty(core.androidRefreshToken) ||
          isEmpty(core.androidVerifierOptions.clientId) ||
          isEmpty(core.androidVerifierOptions.clientSecret) ||
          isEmpty(core.androidVerifierOptions.publicKey)) return false;
      if (!await verifyString(
          purchase.verificationData.localVerificationData,
          purchase.billingClientPurchase.signature,
          core.androidVerifierOptions.publicKey)) return false;
      Response response =
          await post("https://accounts.google.com/o/oauth2/token", headers: {
        "content-type": "application/x-www-form-urlencoded"
      }, body: {
        "grant_type": "refresh_token",
        "client_id": core.androidVerifierOptions.clientId,
        "client_secret": core.androidVerifierOptions.clientSecret,
        "refresh_token": core.androidRefreshToken
      });
      if (response.statusCode != 200) return false;
      Map<String, dynamic> map = Json.decodeAsMap(response.body);
      if (map == null) return false;
      String accessToken = map["access_token"];
      if (isEmpty(accessToken)) return false;
      switch (product.type) {
        case ProductType.consumable:
        case ProductType.nonConsumable:
          response = await get(
              "https://www.googleapis.com/androidpublisher/v3/applications/"
              "${purchase.billingClientPurchase.packageName}/purchases/products/"
              "${purchase.productID}/tokens/"
              "${purchase.billingClientPurchase.purchaseToken}?access_token=$accessToken",
              headers: {"content-type": "application/json"});
          break;
        case ProductType.subscription:
          response = await get(
              "https://www.googleapis.com/androidpublisher/v3/applications/"
              "${purchase.billingClientPurchase.packageName}/purchases/subscriptions/"
              "${purchase.productID}/tokens/"
              "${purchase.billingClientPurchase.purchaseToken}?access_token=$accessToken",
              headers: {"content-type": "application/json"});
          break;
      }
      if (response.statusCode != 200) return false;
      map = Json.decodeAsMap(response.body);
      switch (product.type) {
        case ProductType.consumable:
        case ProductType.nonConsumable:
          if (map == null || map["purchaseState"] != 0) return false;
          break;
        case ProductType.subscription:
          int startTimeMillis = int.tryParse(map["startTimeMillis"]);
          int expiryTimeMillis = int.tryParse(map["expiryTimeMillis"]);
          if (map == null ||
              startTimeMillis == null ||
              expiryTimeMillis == null ||
              startTimeMillis <= 0 ||
              expiryTimeMillis <= DateTime.now().toUtc().millisecondsSinceEpoch)
            return false;
          break;
      }
    } else if (Config.isIOS) {
      if (core.iosVerifierOptions == null ||
          isEmpty(core.iosVerifierOptions.sharedSecret)) return false;
      Response response = await post(
          "https://buy.itunes.apple.com/verifyReceipt",
          headers: {
            "content-type": "application/json",
            "accept": "application/json"
          },
          body: Json.encode({
            "receipt-data": purchase.verificationData.serverVerificationData,
            "password": core.iosVerifierOptions.sharedSecret,
            "exclude-old-transactions": true
          }));
      if (response.statusCode != 200) return false;
      Map<String, dynamic> map = Json.decodeAsMap(response.body);
      if (map == null) return false;
      int status = map["status"];
      if (status == 21007 || status == 21008) {
        response = await post("https://sandbox.itunes.apple.com/verifyReceipt",
            headers: {
              "content-type": "application/json",
              "accept": "application/json"
            },
            body: Json.encode({
              "receipt-data": purchase.verificationData.serverVerificationData,
              "password": core.iosVerifierOptions.sharedSecret,
              "exclude-old-transactions": true
            }));
        if (response.statusCode != 200) return false;
        map = Json.decodeAsMap(response.body);
        if (map == null || map["status"] != 0) return false;
      } else if (status != 0) {
        return false;
      }
      if( product.type == ProductType.subscription ) {
        int startTimeMillis = int.tryParse( map["latest_receipt_info"].first["purchase_date_ms"] );        
        int expiryTimeMillis = int.tryParse( map["latest_receipt_info"].first["expires_date_ms"] );
        if (map == null ||
            startTimeMillis == null ||
            expiryTimeMillis == null ||
            startTimeMillis <= 0 ||
            expiryTimeMillis <= DateTime.now().toUtc().millisecondsSinceEpoch)
          return false;
      }
    }
    return true;
  }
}
