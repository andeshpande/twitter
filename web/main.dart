import 'dart:html';
import 'dart:async';
import 'dart:convert';

import "package:react/react.dart" as react;
import "package:react/react_client.dart";
import 'package:frappe/frappe.dart';

import 'components.dart';
import 'package:stream_transformers/stream_transformers.dart';

WebSocket initWebSocket([int retrySeconds = 2]) {
  var reconnectScheduled = false;

  var ws = new WebSocket('ws://0.0.0.0:8080/ws');

  void scheduleReconnect() {
    if (!reconnectScheduled) {
      new Timer(new Duration(seconds: retrySeconds), () => initWebSocket(retrySeconds * 2));
    }
    reconnectScheduled = true;
  }

  ws.onOpen.listen((e) {
    ws.send('Hello from Dart!');
  });

  ws.onClose.listen((e) {
    print('closed');
  });

  ws.onError.listen((e) {
    scheduleReconnect();
  });
  
  return ws;
}
// TODO: look into this: https://github.com/danschultz/isomorphic_dart
void main() {

  setClientConfiguration();
  
  var startButton = (document.querySelector('#toggleStream') as ButtonElement);
  
  WebSocket ws = initWebSocket();
  
  var clickToggle = new EventStream(startButton.onClick).scan(true, (prev, _) => !prev);
  
  var jsonStream = new EventStream(ws.onMessage).asBroadcastStream()
      .map((e) => JSON.decode(e.data))
      .when(clickToggle);
  
  react.render(application({'jsonStream': jsonStream}), document.querySelector('#app'));
  
  clickToggle.listen((started) {
    startButton.text = started ? 'Pauze' : 'Start';
  });
  
}