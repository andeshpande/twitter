import 'package:react_stream/react_stream.dart';
import 'package:react/react.dart' as react;
import 'dart:async';
import 'dart:convert';
import 'package:stream_transformers/stream_transformers.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

class Delay implements StreamTransformer {
  Stream durationStream;
  Delay(this.durationStream);
  
  @override
  Stream bind(Stream stream) {
    var str = stream;
    durationStream.map((i) => new Duration(milliseconds:i*30)).listen((_duration) {
        str = stream.asyncMap((event) => new Future.delayed(_duration, () => event));
    });
    
    return str;
  }
}

var sample = (Stream<int> stream) => new StreamTransformer<Map, Map>(
    (Stream<Map> input, bool cancelOnError) {
      
      var str = input;
      stream.map((i) => new Duration(milliseconds:i*30)).listen((duration) {
        
        str = input.transform(new SamplePeriodically(duration));
      });      
      return str.listen(null);
      
//      controller = new StreamController<Map>(
//        onListen: () {
//          
//          stream.map((i) => new Duration(milliseconds:i*30)).listen((duration) {
//            
//            return input.transform(new SamplePeriodically(duration));
//            
////            input.asyncMap((event) => new Future.delayed(duration, () => event)).listen((data) {
////              controller.add(data);
////            });
//    
//          },
//          onError: controller.addError,
//          onDone: controller.close,
//          cancelOnError: cancelOnError);
//        },
//        sync: true);
//      
//      return controller.stream;
    });

class ApplicationComponent extends StreamComponent {
  
//  Stream get _jsonStream => (props['jsonStream'] as Stream).transform(new When(_durationStream));
//  Stream get _jsonStream => (props['jsonStream'] as Stream).transform(sample(_durationStream));
//  Stream get _jsonStream => (props['jsonStream'] as Stream).transform(new SamplePeriodically(new Duration(milliseconds:1000)));
  Stream get _jsonStream => (props['jsonStream'] as Stream);
  
  Stream _tweetStream;
  Stream<Map> _langStream;
  StreamController _detailController = new StreamController();
  StreamController _durationController = new StreamController();
  Stream get _detailStream => _detailController.stream;
  Stream get _durationStream => _durationController.stream;
  
  Function filter = (data) => true;
    
  componentWillMount() {
//    _durationController.add(50);
    
    _tweetStream = _jsonStream.where((Map data) => data.containsKey('created_at'));
    
    _langStream = _tweetStream.map((data) => data['lang']);
    
//    _durationStream.listen(print);
    
    
  }
  
  setFilter(Function f) {
    this.filter = f;
    redraw();
  }
  
  @override
  render() {
    return react.div({'key':'ct', 'className': 'container'}, [
      react.input({'key':'ir', 'type': 'range', 'onChange': _durationController.add}, ''),
      languageFilter({'key':'lf', 'langs': _langStream, 'click': setFilter}),
      tweetList({'key':'tl', 'tweets': _tweetStream, 'click': _detailController.add, 'filter':filter}),
      detail({'key' : 'dt', 'detailStream': _detailStream}),
    ]);
  }
}
var application = react.registerComponent(() => new ApplicationComponent());

class TweetListComponent extends StreamComponent {
  
  Stream get _tweetStream => props['tweets'];
  List tweets = [];
  get filter => props['filter'];
  var selected;
  
  handleClick(e, t) {
    selected = t;
    props['click'](t);
    redraw();
  }
  
//  get stateStream => props['tweets'];
  
  componentWillMount() {
        
    _tweetStream.listen((tweet) {
      tweets.insert(0, tweet);
      redraw();
    });    
  }
  
  @override
  render() {
    return react.div({'key': 'created', 'className': 'col-sm-5'}, 
      tweets.where(filter).map((t) {
        return react.pre({
            'key': t['id_str'], 
            'onClick': (e) => handleClick(e, t),
            'className': selected == t ? 'selected' : '',
          }, 
            t['text']
        );    
      })
    );
  }
}
var tweetList = react.registerComponent(() => new TweetListComponent());

class LanguageFilterComponent extends StreamComponent {
  
  get _langStream => props['langs'];
  List langs = [{'lang': 'all', 'count': 0}]; // [{lang, count}]
  var selected;
  
  componentWillMount() {
    _langStream.listen((lang) {
      _addLang(lang);
      redraw();
    });    
  }
  
  _addLang(lang) {
    var l = langs.firstWhere((e) => e['lang'] == lang, orElse: () => null);
    var all = langs.firstWhere((e) => e['lang'] == 'all');
    all['count']++;
    if(l != null) {
      l['count']++;
    } else {
      langs.add({'lang': lang, 'count': 1});
    }
  }
  
  handleClick(e, lang) {
    selected = lang;
    props['click']((data) => lang['lang'] == 'all' || data['lang'] == lang['lang']);
    redraw();
  }
  
  @override
  render() {   
    langs.sort((e1,e2) => e2['count'] - e1['count']);
    
    return react.ul({'key':'ul', 'id': 'langs', 'className': 'col-sm-2 list-group'},
      langs.map((lang) {
        return react.li({
            'key': lang['lang'], 
            'className': 'list-group-item' + (selected == lang ? ' selected' : ''),
            'onClick': (e) => handleClick(e, lang)
          }, [
            lang['lang'],
            react.span({'className':'badge', 'key': 'badge'}, lang['count'])  
        ]);    
      })
    ); 
  }
}
var languageFilter = react.registerComponent(() => new LanguageFilterComponent());

class PropertyComponent extends StreamComponent {
  String key;
  var value;
  
  
  
  @override
  render() {
    
    var children;
    
    return react.div({}, [
      react.span({}, key),
      value.runtimeType == Map
    ]);
  }
}

class DetailComponent extends StreamComponent {
  var encoder = new JsonUtf8Encoder(' ');
  
  Stream get detailStream => props['detailStream'];
  
  combine(String prev, Map curr) {
    
    var diffString = UTF8.decode(encoder.convert(curr));
    
    var d = diff(prev, diffString);
    cleanupSemantic(d);
    
    var currList = d.map((d) {
      var a = '';
      switch(d.operation) {
//        case DIFF_DELETE: a = react.span({'className': 'deleted'}, d.text); break;  
        case DIFF_EQUAL: a = react.span({'className': 'text-muted'}, d.text); break;
        case DIFF_INSERT: a = react.span({'className': 'added'}, d.text); break;  
      }
      return a;
    });        
    
    var prevList = d.map((d) {
      var a = '';
      switch(d.operation) {
        case DIFF_DELETE: a = react.span({'className': 'deleted'}, d.text); break;  
        case DIFF_EQUAL: a = react.span({'className': 'text-muted'}, d.text); break;
//        case DIFF_INSERT: a = react.span({'className': 'added'}, d.text); break;  
      }
      return a;
    });
        
    setState({'prevList': prevList, 'currList': currList});
    return diffString;
  }
  
  componentWillMount() {
    detailStream.transform(new Scan("", combine)).listen((detail) {
      
//      setState(detail);
    });
  }
  
  @override
  render() {
    return react.pre({'key':'dt', 'className': 'col-sm-5 details'}, [
      react.div({'className':'curr'}, state['currList']),
      react.div({'className':'prev'}, state['prevList']),
    ]);
  }
}
var detail = react.registerComponent(() => new DetailComponent());