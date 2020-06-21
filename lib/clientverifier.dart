part of masamune.purchase;

/// Class for managing billing process.
///
/// Initialize by first executing [initialize()].
///
/// Then purchasing item by executing [purchase()].
class ClientVerifier {
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
    return map["refresh_token"];
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
          isEmpty(core.androidVerifierOptions.refreshToken) ||
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
        "refresh_token": core.androidVerifierOptions.refreshToken
      });
      if (response.statusCode != 200) return false;
      Map<String, dynamic> map = Json.decodeAsMap(response.body);
      if (map == null) return false;
      String accessToken = map["access_token"];
      if (isEmpty(accessToken)) return false;
      response = await get(
          "https://www.googleapis.com/androidpublisher/v3/applications/"
          "${purchase.billingClientPurchase.packageName}/purchases/products/"
          "${purchase.productID}/tokens/"
          "${purchase.billingClientPurchase.purchaseToken}?access_token=$accessToken",
          headers: {"content-type": "application/json"});
      if (response.statusCode != 200) return false;
      map = Json.decodeAsMap(response.body);
      if (map == null || map["purchaseState"] != 0) return false;
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
            }));
        if (response.statusCode != 200) return false;
        map = Json.decodeAsMap(response.body);
        if (map == null || map["status"] != 0) return false;
      } else if (status != 0) {
        return false;
      }
    }
    return true;
  }
}
