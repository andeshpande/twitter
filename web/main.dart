import 'dart:html';
import 'dart:convert';

import "package:react/react.dart" as react;
import "package:react/react_client.dart";
import 'package:frappe/frappe.dart';

import 'components.dart';

void main() {

  setClientConfiguration();
  
//  var startButton = (document.querySelector('#toggleStream') as ButtonElement);
  
  WebSocket ws = new WebSocket('ws://0.0.0.0:8080/ws');
  ws.onOpen.listen((e) => ws.send('Hello from Dart!'));
  
//  var clickToggle = new EventStream(startButton.onClick).scan(true, (prev, _) => !prev);
//  clickToggle.listen((started) {
//    startButton.text = started ? 'Pauze' : 'Start';
//  });
  
  var jsonStream = new EventStream(ws.onMessage).asBroadcastStream()
      .map((e) => JSON.decode(e.data))
//      .when(clickToggle)
    ;
  
  react.render(application({'jsonStream': jsonStream}), document.querySelector('#app'));
  
}