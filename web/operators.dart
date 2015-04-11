import 'dart:async';

Stream rateController (Stream inputStream, interval){
  StreamController controller = new StreamController.broadcast();
  List buff = [];
  
  inputStream.listen((event) => buff.add(event));
  new Timer.periodic(new Duration(seconds: interval), (timer) {
    controller.add(buff.removeAt(0));
  });
  
  return controller.stream;
}

Stream merge(Stream a, Stream b) {
  StreamController controller = new StreamController.broadcast();
  var completer_a = new Completer();
  var completer_b = new Completer();
  
  a.listen((event) => controller.add(event),
      onDone  : completer_a.complete());
  b.listen((event) => controller.add(event),
      onDone  : completer_b.complete());
 /* 
  Future
      .wait([completer_a.future, completer_b.future])
      .then((_) => controller.close());
  */
  return controller.stream;
}