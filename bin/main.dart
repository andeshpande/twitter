// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:twitter/twitter.dart' as twitter;
import 'dart:async';
import 'dart:convert';
import 'package:oauth/oauth.dart' as oauth;
import 'dart:io';
import 'package:json_object/json_object.dart';

class TwitterKey {

  oauth.Token consumer;
  oauth.Token user;

  TwitterKey.createKey(String consumerKey,String consumerSecret,
                              String accessToken,String accessSecret) {

    this.consumer = createToken(consumerKey,consumerSecret);
    this.user = createToken(accessToken,accessSecret);
  }

}

oauth.Token createToken(String key, String secret) {
  return new oauth.Token(key, secret);
}



main() {
 
  // authorization string from https://dev.twitter.com/oauth/tools/signature-generator/7220915?nid=875
  var authorization = 'OAuth oauth_consumer_key="PLLYguQdJqooNfAKwTlZe5MMi", oauth_nonce="b3b3626a4c5806bcc8601d98fe7d0d51", oauth_signature="lare0FLb8SNyITNJlJYkXLLEKH8%3D", oauth_signature_method="HMAC-SHA1", oauth_timestamp="1426774910", oauth_token="2238912169-ThdEALf8Wxbg1aCpIVEMWD64tphM1hXipLJe2MM", oauth_version="1.0"';
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
