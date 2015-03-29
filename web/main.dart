import 'dart:html';
import 'dart:async';
import 'dart:convert';

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
// TODO: look into this: https://github.com/danschultz/isomorphic_dart
void main() {
  initWebSocket();
  
  // the json stream:
  var jsonStream = ws.onMessage.map((e) => JSON.decode(e.data));
   
  var deletedStream = jsonStream.where((Map data) => data.containsKey('delete'));
  var createdStream = jsonStream.where((Map data) => !data.containsKey('delete'));
   
  var deletedDiv = (document.querySelector('#deleted') as DivElement);
  var createdDiv = (document.querySelector('#created') as DivElement);
  
  deletedStream.listen((data) {
    deletedDiv.insertBefore(new PreElement()..text = '${data['delete']['status']['id']}', deletedDiv.firstChild);          
  });
   
  createdStream.listen((data) {
    createdDiv.insertBefore(new PreElement()..text = data['text'], createdDiv.firstChild);          
  });
   
//   jsonStream.listen(print);
}