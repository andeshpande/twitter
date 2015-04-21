import 'dart:convert';
import 'dart:io';
import 'dart:core';
import 'dart:async';
import 'package:twitter/twitter_oauth.dart';

import 'package:redstone/server.dart' as app;
import 'package:redstone_web_socket/redstone_web_socket.dart';
import 'package:redstone/server.dart';

Stream twitterStream;
void main() {
  
  getTwitterStream().then((ts) {
    twitterStream = ts.asBroadcastStream();
    
    app.setupConsoleLog();
    app.addPlugin(getWebSocketPlugin());

    app.start(port:8888);
  });
}

@Route('/')
hello() => 'hello';

@WebSocketHandler("/ws")
onConnection(websocket) {
  twitterStream.pipe(websocket);
}  

//@WebSocketHandler("/ws")
//class ServerEndPoint {
//
//  @OnMessage() 
//  void onMessage(String message, WebSocketSession session) {
//    
//    if(message == 'done') {
//      session.connection.close();
//    } else {
//      twitterStream.pipe(session.connection);
//    }
//  }
//  
//  @OnError() onError(WebSocketSession session) => print("help");
//  
//
//  @OnOpen() onOpen(WebSocketSession session) => print("connection established");
//  @OnClose() onClose(WebSocketSession session) => print("connection closed");
//}


Future<Stream> getTwitterStream() {
   
  // Get the params from http://apps.twitter.com
  Map params = {
    'oauth_consumer_key'   :  'QSW4maKbx5jsWzDLxg48DPsO6',
    'oauth_consumer_secret':  'xCLaSQcJPc3Mj4ATSFpsBUhCSlA81P2QPD7Ayc3c411x7sUrte', 
    'oauth_token'          :  '195336429-GNz0lzQybqlLpX6xLKjeAO8H33aI2738ZAo6C79e',
    'oauth_access_secret'  :  '2E4oUKx0ftBilcnrPif4b6UM8JgePJjzQ17g86qvdNrQE',
    'oauth_method'         :  'HMAC-SHA1',
    'oauth_version'        :  '1.0'
  };
  
  var url = "https://stream.twitter.com/1.1/statuses/sample.json";
  var authorization = new OAuthTwitter(params).getAuthorizationHeaders(url);
  
  return new HttpClient().getUrl(Uri.parse(url))
  
  .then((HttpClientRequest request) {
    // Prepare the request.
    request.headers
      ..set('Authorization', authorization)
      ..set('User-Agent', 'OAuth gem v0.4.4')
      ..set('accept', '*/*')
    ;
    
    return request.close();
  })
  .then((HttpClientResponse response) {
    // Process the response.
    return response.transform(UTF8.decoder).transform(repair);
  });
}

// Sometimes a stream item is only part of a json string, and thus
// needs to be buffered so we can repair it by glueing the parts back together.
var repair = new StreamTransformer<String, String>(
    (Stream<String> input, bool cancelOnError) {
      var bufferedString = '';
      
      StreamController<String> controller;
            
      controller = new StreamController<String>(
        onListen: () {
          input.listen((data) {

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