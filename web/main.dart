import 'dart:html';
import 'dart:convert';

import 'package:react/react.dart';
import 'package:react/react_client.dart';
import 'package:frappe/frappe.dart';

import 'components.dart';

void main() {

  setClientConfiguration();
  
  WebSocket ws = new WebSocket('ws://0.0.0.0:8080/ws');
  ws.onOpen.listen((e) => ws.send('Hello from Dart!'));
  
  var jsonStream = new EventStream(ws.onMessage)
      .map((e) => JSON.decode(e.data))
      .asBroadcastStream()
    ;
  
  render(application({'jsonStream': jsonStream}), document.querySelector('#app'));
  
}