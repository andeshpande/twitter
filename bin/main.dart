// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart' as crypto;
import 'dart:core';

String create_nonce(){
  math.Random rnd = new math.Random();
  List<int> values = new List<int>.generate(32, (i) => rnd.nextInt(256));
  var oauth_nonce = crypto.CryptoUtils.bytesToBase64(values).replaceAll(new RegExp('[=/+]'), '');
  return oauth_nonce;
}
String computeSignature(List<int> key, List<int> signatureBase) {
  var mac = new crypto.HMAC(new crypto.SHA1(), key);
  mac.add(signatureBase);
  return crypto.CryptoUtils.bytesToBase64(mac.close());
}

String getAuthorizationHeaders() {
  String oauth_consumer_key     = 'QSW4maKbx5jsWzDLxg48DPsO6';                            // Get Consumer Key from http://apps.twitter.com
    String oauth_consumer_secret  = 'xCLaSQcJPc3Mj4ATSFpsBUhCSlA81P2QPD7Ayc3c411x7sUrte'; // Get Consumer Secret from http://apps.twitter.com
    String oauth_token            = '195336429-GNz0lzQybqlLpX6xLKjeAO8H33aI2738ZAo6C79e'; // Get Access Key from http://apps.twitter.com
    String oauth_access_secret    = '2E4oUKx0ftBilcnrPif4b6UM8JgePJjzQ17g86qvdNrQE';      // Get Access Secret from http://apps.twitter.com

    String oauth_method           = 'HMAC-SHA1';
    String oauth_version          = '1.0';
    String oauth_nonce            = create_nonce();
    String timestamp              = (new DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
   
    // A very crude way to create base string for oauth
    String base_string            = "GET&https%3A%2F%2Fstream.twitter.com%2F1.1%2Fstatuses%2Fsample.json&"
                                    +"oauth_consumer_key%3D"        + oauth_consumer_key
                                    +"%26oauth_nonce%3D"            + oauth_nonce
                                    +"%26oauth_signature_method%3D" + oauth_method
                                    +"%26oauth_timestamp%3D"        + timestamp
                                    +"%26oauth_token%3D"            + oauth_token 
                                    +"%26oauth_version%3D"          + oauth_version;
   
          
    String key                    = Uri.encodeComponent(oauth_consumer_secret) + '&' + Uri.encodeComponent(oauth_access_secret);
    String oauth_signature        = Uri.encodeComponent(computeSignature(UTF8.encode(key), UTF8.encode(base_string)));
     
    var authorization = 'OAuth oauth_consumer_key="' + oauth_consumer_key 
        +'", oauth_nonce="'                          + oauth_nonce
        +'", oauth_signature="'                      + oauth_signature
        +'", oauth_signature_method="'               + oauth_method
        +'", oauth_timestamp="'                      + timestamp
        +'", oauth_token="'                          + oauth_token
        +'", oauth_version="'                        + oauth_version
        +'"';
    
    return authorization;
}

main() {
 
  var authorization = getAuthorizationHeaders();
  // print(authorization);
  var url = "https://stream.twitter.com/1.1/statuses/sample.json";
  new HttpClient().getUrl(Uri.parse(url))
  
  .then((HttpClientRequest request) {
    // Prepare the request.
    request.headers.set('Authorization', authorization);
    request.headers.set('User-Agent', 'OAuth gem v0.4.4');
    request.headers.set('accept', '*/*');

    return request.close();
  })
  .then((HttpClientResponse response) {
    // Process the response.
//    response.listen(print);
    response.transform(UTF8.decoder).listen(print);
  });
}
