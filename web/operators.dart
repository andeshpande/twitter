import 'dart:async';

Stream rateController (Stream inputStream, interval){
  StreamController controller = new StreamController.broadcast(sync:true);
  List buff = [];
  
  inputStream.listen((event) => buff.add(event));
  new Timer.periodic(new Duration(seconds: interval), (timer) {
    controller.add(buff.removeAt(0));
  });
  
  return controller.stream;
}