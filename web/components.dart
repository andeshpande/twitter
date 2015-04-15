import 'package:react_stream/react_stream.dart';
import 'package:react/react.dart';
import 'package:frappe/frappe.dart';
import 'dart:async';
import 'dart:convert';
import 'package:stream_transformers/stream_transformers.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:twitter/util.dart';

class ApplicationComponent extends StreamComponent {
  
  EventStream get _jsonStream => props['jsonStream'];
  
  Stream _tweetStream;
  Stream<Map> _langStream;
  StreamController _detailController = new StreamController();
  Stream get _detailStream => _detailController.stream;
  
  Subject<SyntheticEvent> onChange = new Subject<SyntheticEvent>();  
  
  Function filter = (data) => true;
    
  componentWillMount() {
    
    const MULTIPLIER = 5;
        
    var sliderDuration = onChange.stream
       // map the value of the slider into a duration 
      .map((e) => new Duration(milliseconds: MULTIPLIER * int.parse(e.target.value)));
    
    // We actually wanted to merge a unit stream with the sliderduration,
    // but the merge function is bugged.
    var duration = new Subject<Duration>()
        // the initial value of the slider
        ..add(new Duration(milliseconds: MULTIPLIER*50))
        ..addStream(sliderDuration)
    ;
    
    
    var controlledStream = duration.stream
        //change the speed of the stream
        .flatMapLatest((duration) => _jsonStream.sampleEachPeriod(duration))
        // filter out the empty data created by flatmap
        .where((e) => e.containsKey('lang'))
        .asBroadcastStream();
    
    _tweetStream = controlledStream.where((Map data) => data.containsKey('created_at'));
    
    _langStream = controlledStream.map((data) => data['lang']);
  }
  
  setFilter(Function f) {
    this.filter = f;
    redraw();
  }
  
  @override
  render() {
    
    return div({'key':'ct', 'className': 'container'}, [
      input({'key':'ir', 'type': 'range', 'onChange': onChange}, ''),
      languageFilter({'key':'lf', 'langs': _langStream, 'click': setFilter}),
      tweetList({'key':'tl', 'tweets': _tweetStream, 'click': _detailController.add, 'filter':filter}),
      detail({'key' : 'dt', 'detailStream': _detailStream}),
    ]);
  }
}
var application = registerComponent(() => new ApplicationComponent());

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
    return div({'key': 'created', 'className': 'col-sm-5'}, 
      tweets.where(filter).map((t) {
        return pre({
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
var tweetList = registerComponent(() => new TweetListComponent());

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
    
    return ul({'key':'ul', 'id': 'langs', 'className': 'col-sm-2 list-group'},
      langs.map((lang) {
        return li({
            'key': lang['lang'], 
            'className': 'list-group-item' + (selected == lang ? ' selected' : ''),
            'onClick': (e) => handleClick(e, lang)
          }, [
            lang['lang'],
            span({'className':'badge', 'key': 'badge'}, lang['count'])  
        ]);    
      })
    ); 
  }
}
var languageFilter = registerComponent(() => new LanguageFilterComponent());

class PropertyComponent extends StreamComponent {
  String key;
  var value;
  
  
  
  @override
  render() {
    
    var children;
    
    return div({}, [
      span({}, key),
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
//        case DIFF_DELETE: a = span({'className': 'deleted'}, d.text); break;  
        case DIFF_EQUAL: a = span({'className': 'text-muted'}, d.text); break;
        case DIFF_INSERT: a = span({'className': 'added'}, d.text); break;  
      }
      return a;
    });        
    
    var prevList = d.map((d) {
      var a = '';
      switch(d.operation) {
        case DIFF_DELETE: a = span({'className': 'deleted'}, d.text); break;  
        case DIFF_EQUAL: a = span({'className': 'text-muted'}, d.text); break;
//        case DIFF_INSERT: a = span({'className': 'added'}, d.text); break;  
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
    return pre({'key':'dt', 'className': 'col-sm-5 details'}, [
      div({'className':'curr'}, state['currList']),
//      div({'className':'prev'}, state['prevList']),
    ]);
  }
}
var detail = registerComponent(() => new DetailComponent());