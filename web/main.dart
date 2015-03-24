import 'dart:html';
import 'dart:async';

WebSocket ws;

void initWebSocket([int retrySeconds = 2]) {
  var reconnectScheduled = false;

  ws = new WebSocket('ws://0.0.0.0:8080/ws');

  void scheduleReconnect() {
    if (!reconnectScheduled) {
      new Timer(new Duration(milliseconds: 1000 * retrySeconds), () => initWebSocket(retrySeconds * 2));
    }
    reconnectScheduled = true;
  }

  ws.onOpen.listen((e) {
    ws.send('Hello from Dart!');
  });

  ws.onClose.listen((e) {
    scheduleReconnect();
  });

  ws.onError.listen((e) {
    scheduleReconnect();
  });
}

void main() {
  initWebSocket();
  
  // the json stream:
   var jsonStream = ws.onMessage.map((e) => e.data);
   jsonStream.listen(print);
}