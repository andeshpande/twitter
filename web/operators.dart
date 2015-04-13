import 'dart:async';

class Operator {
    
          
    Stream rateController (Stream inputStream, interval){
      StreamController controller = new StreamController.broadcast();
      List buff = [];
      
      inputStream.listen((event) => buff.add(event));
      new Timer.periodic(new Duration(seconds: interval), (timer) {
        if(buff.isNotEmpty) controller.add(buff.removeAt(0));
      });
      
      return controller.stream;
    }
//-----------------------------------------------------------------------------    
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
//-----------------------------------------------------------------------------    
    Stream buffer(Stream inputStream, int size) {
      StreamController controller = new StreamController.broadcast();
      List buff = new List();
      
      inputStream.listen((event) {
        if(buff.length == size) {controller.add(buff); buff = [];}
        else buff.add(event);
      });
     return controller.stream; 
    }
//-----------------------------------------------------------------------------    
    Stream zip(Stream a, Stream b, dynamic f(dynamic itemA, dynamic itemB)) {
      StreamController controller = new StreamController.broadcast();
      List aBuff = [];
      List bBuff = [];
      
      void handle(List current, List secondary, dynamic event) {
        current.add(event);
        if(secondary.isEmpty) {return;}
        else {
          var aItem = aBuff.removeAt(0);
          var bItem = bBuff.removeAt(0);
          controller.add(f(aItem, bItem));
        }
      }
      
      a.listen((event) => handle(aBuff, bBuff, event));
      b.listen((event) => handle(bBuff, aBuff, event));
      
      return controller.stream;
    }
//-----------------------------------------------------------------------------    
    Stream filter(Stream input, dynamic f(dynamic event)) {
      StreamController controller = new StreamController.broadcast();
      input.listen((event) {
        var x = f(event);
        if(x!= null)controller.add(x);
      });
      
      return controller.stream;
    }
//-----------------------------------------------------------------------------    
    Stream timeInterval(Stream input) {
      StreamController controller = new StreamController.broadcast();
      Stopwatch stopwatch = new Stopwatch()..start();
      int prevTimeStamp = 0;      
      input.listen((event) {
        int currTimeStamp = stopwatch.elapsedMilliseconds.toInt();
        int interval = currTimeStamp - prevTimeStamp;
        controller.add(interval);
        prevTimeStamp = currTimeStamp;
      });
      
      return controller.stream;
    }
}