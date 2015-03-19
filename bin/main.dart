// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:twitter/twitter.dart' as twitter;
import 'dart:async';
import 'dart:convert';
import 'package:oauth/oauth.dart' as oauth;
import 'package:json_object/json_object.dart';

class TwitterKey {

  oauth.Token consumer;
  oauth.Token user;

  static TwitterKey createKey(String consumerKey,String consumerSecret,
                              String accessToken,String accessSecret) {

    oauth.Token consumer = createToken(consumerKey,consumerSecret);
    oauth.Token user = createToken(accessToken,accessSecret);

    return new TwitterKey()
        ..consumer = consumer
        ..user = user;

  }
}

oauth.Token createToken(String key, String secret) {
  return new oauth.Token(key, secret);
}



main() {
  String consumerKey    = "QSW4maKbx5jsWzDLxg48DPsO6";
  String consumerSecret = "xCLaSQcJPc3Mj4ATSFpsBUhCSlA81P2QPD7Ayc3c411x7sUrte";
  String accessKey      = "195336429-GNz0lzQybqlLpX6xLKjeAO8H33aI2738ZAo6C79e";
  String accessSecret   = "2E4oUKx0ftBilcnrPif4b6UM8JgePJjzQ17g86qvdNrQE";
  
  TwitterKey key = TwitterKey.createKey(consumerKey, consumerSecret, accessKey, accessSecret);
 
  var comp    = new Completer();
  var client  = new oauth.Client(key.consumer);
  client.userToken = key.user;
  var stream = client.get("https://stream.twitter.com/1.1/statuses/sample.json").asStream();
  
  stream.transform(UTF8.decoder)
        .transform(const LineSplitter())
        .listen((value) {
          print("value: $value");
  });

 
 /*
  .then((response){
            if (response.statusCode == 200 || response.statusCode == 201){
              print("It works\n");
              comp.complete(JSON.decode(response.body));
            }
            else {
              print("Needs repair.\n");
            }
    });
  
  * 
   */
  print("Hello\n");
}
