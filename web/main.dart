import 'dart:html';
import 'dart:async';
import 'dart:convert';

import "package:react/react.dart" as react;
import "package:react/react_client.dart";

import 'components.dart';
import 'operators.dart' as op;

WebSocket ws;

void initWebSocket([int retrySeconds = 2]) {
  var reconnectScheduled = false;

  ws = new WebSocket('ws://127.0.0.1:8080/ws');

  void scheduleReconnect() {
    if (!reconnectScheduled) {
      new Timer(new Duration(seconds: retrySeconds), () => initWebSocket(retrySeconds * 2));
    }
    reconnectScheduled = true;
  }

  ws.onOpen.listen((e) {
    ws.send('Hello from Dart!');
  });

//  ws.onClose.listen((e) {
//    scheduleReconnect();
//  });

  ws.onError.listen((e) {
    scheduleReconnect();
  });
}

// Some filter for a stream
dynamic test(dynamic event) {
  if(event.containsKey('delete')) return event;
  else return null;
}

void main() {
  initWebSocket();
  var jsonStream = ws.onMessage.map((e) => JSON.decode(e.data));
  Stream a = jsonStream.where((Map data) => data.containsKey('created_at'));
  Stream b = jsonStream.where((Map data) => data.containsKey('delete'));
  Stream c = op.filter(jsonStream, test);
  //op.timeInterval(c).listen(print);
  op.timeInterval(op.rateController(jsonStream, 3)).listen(print);
}
/*
// TODO: look into this: https://github.com/danschultz/isomorphic_dart
void main() {

  setClientConfiguration();
  
  var startButton = (document.querySelector('#toggleStream') as ButtonElement);
  
  startButton.onClick.listen((e) {
    
    if(startButton.text == 'Start') {
      startButton.text = 'pauze';
      initWebSocket();
      
      var jsonStream = ws.onMessage.map((e) => JSON.decode(e.data));
      react.render(application({'jsonStream': jsonStream}), document.querySelector('#app'));
      
           
    } else {
      ws.close();
      startButton.text = 'Start';
      
    }
  });
  
}
*/