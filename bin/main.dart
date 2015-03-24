// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:oauth/oauth.dart' as oauth;
import 'dart:io';
import 'dart:math';
import 'package:oauth/src/core.dart';
import 'package:crypto/crypto.dart' as crypto;


Map<String, String> generateParameters(
    HttpClientRequest request, 
    oauth.Token consumerToken, 
    oauth.Token userToken, 
    String nonce,
    int timestamp) {
  Map<String, String> params = new Map<String, String>();
  params["oauth_consumer_key"] = consumerToken.key;
  if(userToken != null) {
    params["oauth_token"] = userToken.key;
  }
  
  params["oauth_signature_method"] = "HMAC-SHA1";
  params["oauth_version"] = "1.0";
  params["oauth_nonce"] = nonce;
  params["oauth_timestamp"] = timestamp.toString();
  
  List<Parameter> requestParams = new List<Parameter>();
  requestParams.addAll(mapParameters(request.uri.queryParameters));
  requestParams.addAll(mapParameters(params));
  
//  if(request.contentLength != 0
//      && request.headers.value("Content-Type") == "application/x-www-form-urlencoded") {
//    requestParams.addAll(mapParameters(request.bodyFields));
//  } 
  
  var sigBase = computeSignatureBase(request.method, request.uri, requestParams);
  var sigKey = computeKey(consumerToken, userToken);
  params["oauth_signature"] = computeSignature(sigKey, sigBase);
  
  return params;
}

var credentials = {
  'consumerKey': 'PLLYguQdJqooNfAKwTlZe5MMi',                 
  'consumerSecret': 'F4gQOWBt8OAyAfu3X9cPzt4osCsMchv3y6WnkNtFAs0uEOmgmr',                 
  'accessToken': '2238912169-ThdEALf8Wxbg1aCpIVEMWD64tphM1hXipLJe2MM',                 
  'accessTokenSecret': '0faSzZzfArxW2nMALeZPl3Rguh3smyL4afp4AgdINFm8r',                 
};

var url = "https://stream.twitter.com/1.1/statuses/sample.json";

main() {
  var token = new oauth.Token(credentials['consumerKey'], credentials['consumerSecret']);
  var userToken = new oauth.Token(credentials['accessToken'], credentials['accessTokenSecret']);
  
  new HttpClient().getUrl(Uri.parse(url))
  
  .then((HttpClientRequest request) {
    // Prepare the request.
    request.headers.set('User-Agent', 'OAuth gem v0.4.4');
    request.headers.set('accept', '*/*');
    
    var timestamp = new DateTime.now().millisecondsSinceEpoch / 1000; // seconds
    
    var r = new Random();
    var nonce = new List<int>.generate(8, (_) => r.nextInt(255), growable: false);
    String nonceStr = crypto.CryptoUtils.bytesToBase64(nonce, urlSafe: true);
    
    var authorization = oauth.produceAuthorizationHeader(generateParameters(request, token, userToken, nonceStr, timestamp.toInt()));
    print(authorization);
    
    request.headers.set('Authorization', authorization);

    return request.close();
  })
  .then((HttpClientResponse response) {
    // Process the response.
    response.transform(UTF8.decoder).listen(print);
  });
}
