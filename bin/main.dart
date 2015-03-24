// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart' as crypto;
import 'dart:core';
import 'package:json_object/json_object.dart';
import 'dart:async';


class oauth_twitter {
    String _oauth_consumer_key;   
    String _oauth_consumer_secret;  
    String _oauth_token;            
    String _oauth_access_secret;    
    String _oauth_method;      
    String _oauth_version;
    String _oauth_nonce;           
    String _timestamp;             
    
    oauth_twitter(params){
            _oauth_consumer_key     = params['oauth_consumer_key'];
            _oauth_consumer_secret  = params['oauth_consumer_secret'];
            _oauth_token            = params['oauth_token'];
            _oauth_access_secret    = params['oauth_access_secret'];
            _oauth_method           = params['oauth_method'];
            _oauth_version          = params['oauth_version'];

            _oauth_nonce            = _create_nonce();
            _timestamp              = (new DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    }
  
    String _create_nonce(){
      math.Random rnd = new math.Random();
      List<int> values = new List<int>.generate(32, (i) => rnd.nextInt(256));
      var oauth_nonce = crypto.CryptoUtils.bytesToBase64(values).replaceAll(new RegExp('[=/+]'), '');
      return oauth_nonce;
    }
    
    String _computeSignature(List<int> key, List<int> signatureBase) {
      var mac = new crypto.HMAC(new crypto.SHA1(), key);
      mac.add(signatureBase);
      return crypto.CryptoUtils.bytesToBase64(mac.close());
    }
    
    String getAuthorizationHeaders() {
              
        // A very crude way to create base string for oauth
        String _base_string            = "GET&https%3A%2F%2Fstream.twitter.com%2F1.1%2Fstatuses%2Fsample.json&"
                                        +"oauth_consumer_key%3D"        + _oauth_consumer_key
                                        +"%26oauth_nonce%3D"            + _oauth_nonce
                                        +"%26oauth_signature_method%3D" + _oauth_method
                                        +"%26oauth_timestamp%3D"        + _timestamp
                                        +"%26oauth_token%3D"            + _oauth_token 
                                        +"%26oauth_version%3D"          + _oauth_version;
       
              
        String _key                    = Uri.encodeComponent(_oauth_consumer_secret) + '&' + Uri.encodeComponent(_oauth_access_secret);
        String _oauth_signature        = Uri.encodeComponent(_computeSignature(UTF8.encode(_key), UTF8.encode(_base_string)));
         
        var authorization = 'OAuth oauth_consumer_key="' + _oauth_consumer_key 
            +'", oauth_nonce="'                          + _oauth_nonce
            +'", oauth_signature="'                      + _oauth_signature
            +'", oauth_signature_method="'               + _oauth_method
            +'", oauth_timestamp="'                      + _timestamp
            +'", oauth_token="'                          + _oauth_token
            +'", oauth_version="'                        + _oauth_version
            +'"';
        
        return authorization;
    }
}


void handleStream(response) {
//  print(response);
  var value = JSON.decode(response);
   print(value);
   /* if response is decoded directly,
    * error "Unexpected end of string"
    * or error "Unexpected charaacter at [some_position]
    * is encountered
    */ 
//   JsonObject data = new JsonObject.fromJsonString(value);
//   print(data);
   // Cannot get values from data either :(
      
}


main() {
   
  String consumer_key     = 'QSW4maKbx5jsWzDLxg48DPsO6';                          // Get Consumer Key from http://apps.twitter.com
  String consumer_secret  = 'xCLaSQcJPc3Mj4ATSFpsBUhCSlA81P2QPD7Ayc3c411x7sUrte'; // Get Consumer Secret from http://apps.twitter.com
  String access_token     = '195336429-GNz0lzQybqlLpX6xLKjeAO8H33aI2738ZAo6C79e'; // Get Access Key from http://apps.twitter.com
  String access_secret    = '2E4oUKx0ftBilcnrPif4b6UM8JgePJjzQ17g86qvdNrQE';      // Get Access Secret from http://apps.twitter.com
  String method           = 'HMAC-SHA1';
  String version          = '1.0';

  Map params = {'oauth_consumer_key'   :  consumer_key,
                'oauth_consumer_secret':  consumer_secret,
                'oauth_token'          :  access_token,
                'oauth_access_secret'  :  access_secret,
                'oauth_method'         :  method,
                'oauth_version'        :  version
                };
  
  oauth_twitter obj = new oauth_twitter(params); 
  var authorization = obj.getAuthorizationHeaders();
  
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
    response.transform(UTF8.decoder).transform(buffer).listen(handleStream);
  });
}

var buffer = new StreamTransformer<String, String>(
    (Stream<String> input, bool cancelOnError) {
      var bufferedString = '';
      
      StreamController<String> controller;
      
      StreamSubscription<String> subscription;
      
      controller = new StreamController<String>(
        onListen: () {
          subscription = input.listen((data) {

            if(data.endsWith('\n')) {
              
              if(!bufferedString.endsWith('\n')) {
                controller.add(bufferedString+data); 
                bufferedString = '';
              } else 
                controller.add(data);
            }
            else
              bufferedString += data;
          },
          onError: controller.addError,
          onDone: controller.close,
          cancelOnError: cancelOnError);
        },
        sync: true);
      
      return controller.stream.listen(null);
    });