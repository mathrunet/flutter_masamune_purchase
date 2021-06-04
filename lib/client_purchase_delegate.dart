part of masamune_purchase;

// /// Class for managing billing process.
// ///
// /// Initialize by first executing [initialize()].
// ///
// /// Then purchasing item by executing [purchase()].
// class ClientPurchaseDelegate {
//   /// Get data for purchased subscriptions.
//   ///
//   /// [purchase]: PurchaseDetails.
//   /// [product]: The purchased product.
//   /// [core]: Purchase Core instance.
//   static Future<DynamicMap?> getSubscribedInfo(
//       PurchaseDetails purchase,
//       PurchaseProduct product,
//       PurchaseCore core) async {
//     if (Config.isAndroid) {
//       if (core.androidRefreshToken.isEmpty ||
//           core.androidVerifierOptions.clientId.isEmpty ||
//           core.androidVerifierOptions.clientSecret.isEmpty ||
//           core.androidVerifierOptions.publicKey.isEmpty) {
//         return null;
//       }
//       if (core.subscribeOptions.expiryDateKey.isEmpty ||
//           core.subscribeOptions.tokenKey.isEmpty ||
//           core.subscribeOptions.orderIDKey.isEmpty ||
//           core.subscribeOptions.packageNameKey.isEmpty ||
//           core.subscribeOptions.productIDKey.isEmpty ||
//           core.subscribeOptions.purchaseIDKey.isEmpty ||
//           core.subscribeOptions.userIDKey.isEmpty) {
//         return null;
//       }
//       var response = await post(
//         Uri.parse("https://accounts.google.com/o/oauth2/token"),
//         headers: {"content-type": "application/x-www-form-urlencoded"},
//         body: {
//           "grant_type": "refresh_token",
//           "client_id": core.androidVerifierOptions.clientId,
//           "client_secret": core.androidVerifierOptions.clientSecret,
//           "refresh_token": core.androidRefreshToken
//         },
//       );
//       if (response.statusCode != 200) {
//         throw Exception(
//             "Server Error: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//       }
//       var map = jsonDecodeAsMap(response.body);
//       if (map.isEmpty) {
//         throw Exception(
//             "Response is empty: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//       }
//       final accessToken = map.get<String>("access_token");
//       if (accessToken.isEmpty) {
//         throw Exception(
//             "Access Token is empty: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//       }
//       response = await get(
//         Uri.parse("https://www.googleapis.com/androidpublisher/v3/applications/"
//             "${purchase.billingClientPurchase?.packageName ?? ""}/purchases/subscriptions/"
//             "${purchase.productID}/tokens/"
//             "${purchase.billingClientPurchase?.purchaseToken ?? ""}?access_token=$accessToken"),
//         headers: {
//           "content-type": "application/json",
//         },
//       );
//       if (response.statusCode != 200) {
//         throw Exception(
//             "Server Error: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//       }
//       map = jsonDecodeAsMap(response.body);
//       if (map.isEmpty) {
//         throw Exception(
//             "Response is empty: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//       }
//       final res = <String, dynamic>{};
//       for (final tmp in map.entries) {
//         if (tmp.key.isEmpty) {
//           continue;
//         }
//         if (tmp.value is String) {
//           final i = int.tryParse(tmp.value as String);
//           if (i == null) {
//             res[tmp.key] = tmp.value;
//           } else {
//             res[tmp.key] = i;
//           }
//         } else {
//           res[tmp.key] = tmp.value;
//         }
//       }
//       final expiryTimeMillis =
//           int.tryParse(map.get<String>("expiryTimeMillis").def("0")) ?? 0;
//       res[core.subscribeOptions.expiryDateKey] = expiryTimeMillis;
//       res[core.subscribeOptions.tokenKey] =
//           purchase.billingClientPurchase?.purchaseToken;
//       res[core.subscribeOptions.purchaseIDKey] = purchase.purchaseID;
//       res[core.subscribeOptions.productIDKey] = purchase.productID;
//       res[core.subscribeOptions.orderIDKey] = map["orderId"];
//       res[core.subscribeOptions.packageNameKey] =
//           purchase.billingClientPurchase?.packageName;
//       res[core.subscribeOptions.platformKey] = "Android";
//       if (core.userId.isNotEmpty) {
//         res[core.subscribeOptions.userIDKey] = core.userId;
//       }
//       if (expiryTimeMillis <= DateTime.now().toUtc().millisecondsSinceEpoch) {
//         res[core.subscribeOptions.expiredKey] = true;
//       }
//       return res;
//     } else if (Config.isIOS) {
//       if (core.iosVerifierOptions.sharedSecret.isEmpty) {
//         return null;
//       }
//       if (core.subscribeOptions.expiryDateKey.isEmpty ||
//           core.subscribeOptions.tokenKey.isEmpty ||
//           core.subscribeOptions.orderIDKey.isEmpty ||
//           core.subscribeOptions.packageNameKey.isEmpty ||
//           core.subscribeOptions.productIDKey.isEmpty ||
//           core.subscribeOptions.purchaseIDKey.isEmpty ||
//           core.subscribeOptions.userIDKey.isEmpty) {
//         return null;
//       }
//       Response response = await post(
//         Uri.parse("https://buy.itunes.apple.com/verifyReceipt"),
//         headers: {
//           "content-type": "application/json",
//           "accept": "application/json"
//         },
//         body: jsonEncode(
//           {
//             "receipt-data": purchase.verificationData.serverVerificationData,
//             "password": core.iosVerifierOptions.sharedSecret,
//             "exclude-old-transactions": true
//           },
//         ),
//       );
//       if (response.statusCode != 200) {
//         throw Exception(
//             "Server Error: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//       }
//       var map = jsonDecodeAsMap(response.body);
//       if (map.isEmpty) {
//         throw Exception(
//             "Response is empty: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//       }
//       final status = map.get<int>("status").def(-1);
//       if (status == 21007 || status == 21008) {
//         response = await post(
//           Uri.parse("https://sandbox.itunes.apple.com/verifyReceipt"),
//           headers: {
//             "content-type": "application/json",
//             "accept": "application/json"
//           },
//           body: jsonEncode(
//             {
//               "receipt-data": purchase.verificationData.serverVerificationData,
//               "password": core.iosVerifierOptions.sharedSecret,
//               "exclude-old-transactions": true
//             },
//           ),
//         );
//         if (response.statusCode != 200) {
//           throw Exception(
//               "Server Error: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//         }
//         map = jsonDecodeAsMap(response.body);
//         if (map.get<int>("status") != 0) {
//           throw Exception(
//               "Verify error: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//         }
//       } else if (status != 0) {
//         throw Exception(
//             "Verify error: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//       }
//       final res = <String, dynamic>{};
//       if (!map.containsKey("latest_receipt_info") ||
//           map.get<List>("latest_receipt_info").isEmpty) {
//         return null;
//       }
//       final latestReceiptInfo =
//           map.get<List<DynamicMap>>("latest_receipt_info");
//       if (latestReceiptInfo.isEmpty) {
//         return null;
//       }
//       final receiptInfo = latestReceiptInfo?.first ?? const {};
//       for (final tmp in receiptInfo.entries) {
//         if (tmp.key.isEmpty || tmp.value == null) {
//           continue;
//         }
//         if (tmp.value is String) {
//           final i = int.tryParse(tmp.value);
//           if (i == null)
//             res[tmp.key] = tmp.value;
//           else
//             res[tmp.key] = i;
//         } else {
//           res[tmp.key] = tmp.value;
//         }
//       }
//       if (!receiptInfo.containsKey("expires_date_ms") ||
//           !receiptInfo.containsKey("transaction_id") ||
//           !map.containsKey("receipt")) {
//         return null;
//       }
//       final reciept = map.get<DynamicMap>("receipt");
//       if (!reciept.containsKey("bundle_id")) {
//         return null;
//       }
//       final expiryTimeMillis =
//           int.tryParse(receiptInfo.get<String>("expires_date_ms").def("0")) ??
//               0;
//       res[core.subscribeOptions.expiryDateKey] = expiryTimeMillis;
//       res[core.subscribeOptions.tokenKey] =
//           purchase.verificationData.serverVerificationData;
//       res[core.subscribeOptions.productIDKey] = purchase.productID;
//       res[core.subscribeOptions.purchaseIDKey] = purchase.purchaseID;
//       res[core.subscribeOptions.orderIDKey] =
//           receiptInfo.get<String>("transaction_id");
//       res[core.subscribeOptions.packageNameKey] =
//           reciept?.get<String>("bundle_id");
//       res[core.subscribeOptions.platformKey] = "IOS";
//       if (core.userId.isNotEmpty) {
//         res[core.subscribeOptions.userIDKey] = core.userId;
//       }
//       if (expiryTimeMillis <= DateTime.now().toUtc().millisecondsSinceEpoch) {
//         res[core.subscribeOptions.expiredKey] = true;
//       }
//       return res;
//     }
//     return null;
//   }

//   /// Monitor subscription status, update, delete, etc.
//   ///
//   /// [core]: PurchaseCore object.
//   static Future<void> checkSubscription(PurchaseCore core) async {
//     if (core.androidRefreshToken.isEmpty ||
//         core.androidVerifierOptions.clientId.isEmpty ||
//         core.androidVerifierOptions.clientSecret.isEmpty ||
//         core.androidVerifierOptions.publicKey.isEmpty) {
//       return;
//     }
//     if (core.iosVerifierOptions.sharedSecret.isEmpty) {
//       return;
//     }
//     if (core.subscribeOptions.expiryDateKey.isEmpty ||
//         core.subscribeOptions.tokenKey.isEmpty ||
//         core.subscribeOptions.orderIDKey.isEmpty ||
//         core.subscribeOptions.platformKey.isEmpty ||
//         core.subscribeOptions.packageNameKey.isEmpty ||
//         core.subscribeOptions.productIDKey.isEmpty ||
//         core.subscribeOptions.userIDKey.isEmpty ||
//         core.subscribeOptions.purchaseIDKey.isEmpty ||
//         core.subscribeOptions.expiredKey.isEmpty) {
//       return;
//     }
//     if (core.subscribeOptions.task == null) {
//       return;
//     }
//     var data = core.subscribeOptions.data;
//     if (core.subscribeOptions.task != null) {
//       data = await core.subscribeOptions.task ?? const [];
//     }
//     final updated = <DynamicMap>[];
//     for (final doc in data) {
//       if (!doc.containsKey(core.subscribeOptions.expiryDateKey) ||
//           !doc.containsKey(core.subscribeOptions.tokenKey) ||
//           !doc.containsKey(core.subscribeOptions.platformKey) ||
//           !doc.containsKey(core.subscribeOptions.orderIDKey) ||
//           !doc.containsKey(core.subscribeOptions.packageNameKey) ||
//           !doc.containsKey(core.subscribeOptions.productIDKey)) {
//         continue;
//       }
//       if (doc.get<bool>(core.subscribeOptions.expiredKey).def(false)) {
//         continue;
//       }
//       final expiryDate =
//           doc.get<int>(core.subscribeOptions.expiryDateKey).def(0);
//       if (expiryDate - DateTime.now().toUtc().millisecondsSinceEpoch >
//           core.subscribeOptions.renewDuration.inMilliseconds) {
//         continue;
//       }
//       debugPrint(
//         "Updating subscription: ${doc.get<String>(core.subscribeOptions.productIDKey)}",
//       );
//       updated.add(doc);
//     }
//     if (updated.isEmpty) {
//       return;
//     }
//     var response = await post(
//       Uri.parse("https://accounts.google.com/o/oauth2/token"),
//       headers: {"content-type": "application/x-www-form-urlencoded"},
//       body: {
//         "grant_type": "refresh_token",
//         "client_id": core.androidVerifierOptions.clientId,
//         "client_secret": core.androidVerifierOptions.clientSecret,
//         "refresh_token": core.androidRefreshToken
//       },
//     );
//     if (response.statusCode != 200) {
//       throw Exception(
//           "Server Error: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//     }
//     var map = jsonDecodeAsMap(response.body);
//     if (map.isEmpty) {
//       throw Exception(
//           "Response is empty: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//     }
//     final accessToken = map.get<String>("access_token");
//     if (accessToken.isEmpty) {
//       throw Exception(
//           "Access Token is empty: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//     }
//     for (final doc in updated) {
//       final platform = doc.get<String>(core.subscribeOptions.platformKey);
//       final token = doc.get<String>(core.subscribeOptions.tokenKey);
//       switch (platform) {
//         case "Android":
//           final packageName =
//               doc.get<String>(core.subscribeOptions.packageNameKey);
//           final productId = doc.get<String>(core.subscribeOptions.productIDKey);
//           if (token.isEmpty || packageName.isEmpty || productId.isEmpty) {
//             continue;
//           }
//           response = await get(
//               Uri.parse(
//                   "https://www.googleapis.com/androidpublisher/v3/applications/"
//                   "$packageName/purchases/subscriptions/"
//                   "$productId/tokens/"
//                   "$token?access_token=$accessToken"),
//               headers: {"content-type": "application/json"});
//           if (response.statusCode != 200) {
//             throw Exception(
//                 "Server Error: ${response.request?.url ?? ""} ${response.statusCode} ${response.body}");
//           }
//           map = jsonDecodeAsMap(response.body);
//           final expiryTimeMillis =
//               int.tryParse(map.get<String>("expiryTimeMillis").def("0")) ?? 0;
//           final orderId = map.get<String>("orderId");
//           if (expiryTimeMillis <
//               DateTime.now().toUtc().millisecondsSinceEpoch) {
//             doc[core.subscribeOptions.expiredKey] = true;
//             await doc.save();
//             Log.msg(
//                 "Expired subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
//           } else if (isNotEmpty(orderId) &&
//               (core.subscribeOptions.existOrderId == null ||
//                   !await core.subscribeOptions.existOrderId(orderId))) {
//             for (MapEntry<String, dynamic> tmp in map.entries) {
//               if (tmp.key.isEmpty || tmp.value == null) continue;
//               if (tmp.value is String) {
//                 int i = int.tryParse(tmp.value);
//                 if (i == null)
//                   document[tmp.key] = tmp.value;
//                 else
//                   document[tmp.key] = i;
//               } else {
//                 document[tmp.key] = tmp.value;
//               }
//             }
//             document[core.subscribeOptions.expiryDateKey] =
//                 int.tryParse(map["expiryTimeMillis"]);
//             document[core.subscribeOptions.orderIDKey] = map["orderId"];
//             await document.save();
//             Log.msg(
//                 "Updated subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
//           }
//           break;
//         case "IOS":
//           if (token.isEmpty) continue;
//           Response response = await post(
//               "https://buy.itunes.apple.com/verifyReceipt",
//               headers: {
//                 "content-type": "application/json",
//                 "accept": "application/json"
//               },
//               body: Json.encode({
//                 "receipt-data": token,
//                 "password": core.iosVerifierOptions.sharedSecret,
//                 "exclude-old-transactions": true
//               }));
//           if (response.statusCode != 200) return null;
//           DynamicMap map = Json.decodeAsMap(response.body);
//           if (map == null) return null;
//           int status = map["status"];
//           if (status == 21007 || status == 21008) {
//             response = await post(
//                 "https://sandbox.itunes.apple.com/verifyReceipt",
//                 headers: {
//                   "content-type": "application/json",
//                   "accept": "application/json"
//                 },
//                 body: Json.encode({
//                   "receipt-data": token,
//                   "password": core.iosVerifierOptions.sharedSecret,
//                   "exclude-old-transactions": true
//                 }));
//             if (response.statusCode != 200) return null;
//             map = Json.decodeAsMap(response.body);
//             if (map == null || map["status"] != 0) return null;
//           }
//           int expiryTimeMillis =
//               int.tryParse(map["latest_receipt_info"].first["expires_date_ms"]);
//           if (expiryTimeMillis == null) continue;
//           String orderId = map["latest_receipt_info"].first["transaction_id"];
//           if (map.containsKey("pending_renewal_info") &&
//               map["pending_renewal_info"].any((info) {
//                 if (!info.containsKey("is_in_billing_retry_period"))
//                   return false;
//                 return info["is_in_billing_retry_period"] == "1";
//               })) {
//             document[core.subscribeOptions.expiryDateKey] = document.getInt(
//                     core.subscribeOptions.expiryDateKey,
//                     DateTime.now().toUtc().millisecondsSinceEpoch) +
//                 core.subscribeOptions.renewDuration.inMilliseconds;
//             await document.save();
//             Log.msg(
//                 "Postponing expiration of subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
//           } else if (map.containsKey("pending_renewal_info") &&
//               expiryTimeMillis <
//                   DateTime.now().toUtc().millisecondsSinceEpoch &&
//               map["pending_renewal_info"].every((info) {
//                 if (!info.containsKey("is_in_billing_retry_period") ||
//                     !info.containsKey("auto_renew_status")) return true;
//                 return info["is_in_billing_retry_period"] != "1" &&
//                     info["auto_renew_status"] != "1";
//               })) {
//             document[core.subscribeOptions.expiredKey] = true;
//             await document.save();
//             Log.msg(
//                 "Expired subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
//           } else if (isNotEmpty(orderId) &&
//               (core.subscribeOptions.existOrderId == null ||
//                   !await core.subscribeOptions.existOrderId(orderId))) {
//             for (MapEntry<String, dynamic> tmp
//                 in map["latest_receipt_info"].first.entries) {
//               if (tmp.key.isEmpty || tmp.value == null) continue;
//               if (tmp.value is String) {
//                 int i = int.tryParse(tmp.value);
//                 if (i == null)
//                   document[tmp.key] = tmp.value;
//                 else
//                   document[tmp.key] = i;
//               } else {
//                 document[tmp.key] = tmp.value;
//               }
//             }
//             document[core.subscribeOptions.expiryDateKey] = int.tryParse(
//                 map["latest_receipt_info"].first["expires_date_ms"]);
//             document[core.subscribeOptions.orderIDKey] =
//                 map["latest_receipt_info"].first["transaction_id"];
//             await document.save();
//             Log.msg(
//                 "Updated subscription: ${document.getString(core.subscribeOptions.productIDKey)}");
//           }
//           break;
//       }
//     }
//   }

//   /// [PurchaseCore] is used as a callback for [onVerify] of [PurchaseCore].
//   ///
//   /// The signature is verified and the receipt is verified locally.
//   ///
//   /// [purchase]: PurchaseDetails.
//   /// [product]: The purchased product.
//   /// [core]: Purchase Core instance.
//   static Future<bool> verify(PurchaseDetails purchase, PurchaseProduct product,
//       PurchaseCore core) async {
//     if (Config.isAndroid) {
//       if (core.androidVerifierOptions == null ||
//           core.androidRefreshToken.isEmpty ||
//           core.androidVerifierOptions.clientId.isEmpty ||
//           core.androidVerifierOptions.clientSecret.isEmpty ||
//           core.androidVerifierOptions.publicKey.isEmpty) return false;
//       if (!await verifyString(
//           purchase.verificationData.localVerificationData,
//           purchase.billingClientPurchase.signature,
//           core.androidVerifierOptions.publicKey)) return false;
//       Response response =
//           await post("https://accounts.google.com/o/oauth2/token", headers: {
//         "content-type": "application/x-www-form-urlencoded"
//       }, body: {
//         "grant_type": "refresh_token",
//         "client_id": core.androidVerifierOptions.clientId,
//         "client_secret": core.androidVerifierOptions.clientSecret,
//         "refresh_token": core.androidRefreshToken
//       });
//       if (response.statusCode != 200) return false;
//       DynamicMap map = Json.decodeAsMap(response.body);
//       if (map == null) return false;
//       String accessToken = map["access_token"];
//       if (accessToken.isEmpty) return false;
//       switch (product.type) {
//         case ProductType.consumable:
//         case ProductType.nonConsumable:
//           response = await get(
//               "https://www.googleapis.com/androidpublisher/v3/applications/"
//               "${purchase.billingClientPurchase.packageName}/purchases/products/"
//               "${purchase.productID}/tokens/"
//               "${purchase.billingClientPurchase.purchaseToken}?access_token=$accessToken",
//               headers: {"content-type": "application/json"});
//           break;
//         case ProductType.subscription:
//           response = await get(
//               "https://www.googleapis.com/androidpublisher/v3/applications/"
//               "${purchase.billingClientPurchase.packageName}/purchases/subscriptions/"
//               "${purchase.productID}/tokens/"
//               "${purchase.billingClientPurchase.purchaseToken}?access_token=$accessToken",
//               headers: {"content-type": "application/json"});
//           break;
//       }
//       if (response.statusCode != 200) return false;
//       map = Json.decodeAsMap(response.body);
//       switch (product.type) {
//         case ProductType.consumable:
//         case ProductType.nonConsumable:
//           if (map == null || map["purchaseState"] != 0) return false;
//           break;
//         case ProductType.subscription:
//           int startTimeMillis = int.tryParse(map["startTimeMillis"]);
//           int expiryTimeMillis = int.tryParse(map["expiryTimeMillis"]);
//           if (map == null ||
//               startTimeMillis == null ||
//               expiryTimeMillis == null ||
//               startTimeMillis <= 0) return false;
//           break;
//       }
//     } else if (Config.isIOS) {
//       if (core.iosVerifierOptions == null ||
//           core.iosVerifierOptions.sharedSecret.isEmpty) return false;
//       Response response = await post(
//           "https://buy.itunes.apple.com/verifyReceipt",
//           headers: {
//             "content-type": "application/json",
//             "accept": "application/json"
//           },
//           body: Json.encode({
//             "receipt-data": purchase.verificationData.serverVerificationData,
//             "password": core.iosVerifierOptions.sharedSecret,
//             "exclude-old-transactions": true
//           }));
//       if (response.statusCode != 200) return false;
//       DynamicMap map = Json.decodeAsMap(response.body);
//       if (map == null) return false;
//       int status = map["status"];
//       if (status == 21007 || status == 21008) {
//         response = await post("https://sandbox.itunes.apple.com/verifyReceipt",
//             headers: {
//               "content-type": "application/json",
//               "accept": "application/json"
//             },
//             body: Json.encode({
//               "receipt-data": purchase.verificationData.serverVerificationData,
//               "password": core.iosVerifierOptions.sharedSecret,
//               "exclude-old-transactions": true
//             }));
//         if (response.statusCode != 200) return false;
//         map = Json.decodeAsMap(response.body);
//         if (map == null || map["status"] != 0) return false;
//       } else if (status != 0) {
//         return false;
//       }
//       if (product.type == ProductType.subscription) {
//         int startTimeMillis =
//             int.tryParse(map["latest_receipt_info"].first["purchase_date_ms"]);
//         int expiryTimeMillis =
//             int.tryParse(map["latest_receipt_info"].first["expires_date_ms"]);
//         if (map == null ||
//             startTimeMillis == null ||
//             expiryTimeMillis == null ||
//             startTimeMillis <= 0) return false;
//       }
//     }
//     return true;
//   }
// }
