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
   
  var createdStream = jsonStream.where((Map data) => data.containsKey('created_at'));
  var langStream = createdStream.map((data) => data['lang']);
   
  var createdDiv = (document.querySelector('#created') as DivElement);
  var langsUl = (document.querySelector('#langs') as UListElement);

  createdStream.listen((data) {
    createdDiv.insertBefore(new PreElement()..text = data['text'], createdDiv.firstChild);          
  });
  
  var langs = <String, int>{};
  langStream.listen((data) {
    if(langs.containsKey(data)) {
      langs[data]++;
      langsUl.querySelector('#$data span').text = '${langs[data]}';
    } else {
      langs[data] = 1;
      
      var li = new LIElement()
          ..text = data
          ..id = data
          ..className = 'list-group-item'
          ..append(new SpanElement()..className = 'badge');
      
      langsUl.insertBefore(li, langsUl.firstChild);          
    }
  });
   
//   jsonStream.listen(print);
}