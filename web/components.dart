import 'package:react_stream/react_stream.dart';
import 'package:react/react.dart';
import 'package:frappe/frappe.dart';
import 'dart:async';
import 'dart:convert';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:twitter/util.dart';

class ApplicationComponent extends StreamComponent {
  
  EventStream get _jsonStream => props['jsonStream'];
  
  Stream tweetStream;
  Stream<Map> langStream;
  Subject onTweetClicked = new Subject();
  Subject onButtonClicked = new Subject();
  bool started = true;
  
  Subject<SyntheticEvent> onSliderChanged = new Subject<SyntheticEvent>();  
  
  Function filter = (data) => true;
    
  
  
  componentWillMount() {
    
    const MULTIPLIER = 5;
        
    var sliderDuration = onSliderChanged.stream
       // map the value of the slider into a duration 
      .map((e) => new Duration(milliseconds: MULTIPLIER * int.parse(e.target.value)));
    
    // We actually wanted to merge a unit stream with the sliderduration,
    // but the merge method is bugged.
    var duration = new Subject<Duration>()
        // the initial value of the slider
        ..add(new Duration(milliseconds: MULTIPLIER*50))
        ..addStream(sliderDuration)
    ;
    
    // Convert the button events to a boolean toggle stream.
    var toggleStream = onButtonClicked.stream.scan(true, (prev, _) => !prev).asBroadcastStream();
    
    var controlledStream = duration.stream
        //change the speed of the stream
        .flatMapLatest((duration) => _jsonStream.sampleEachPeriod(duration))
        // filter out the empty data created by flatmap
        .where((e) => e.containsKey('lang'))
        .when(toggleStream)
        .asBroadcastStream()
      ;
    
    tweetStream = controlledStream.where((Map data) => data.containsKey('created_at'));
    
    langStream = controlledStream.map((data) => data['lang']);
    
    toggleStream.listen((s) => started = s);
    
  }
  
  setFilter(Function f) {
    this.filter = f;
    redraw();
  }
  
  @override
  render() {
    var buttonText = started ? 'Pauze' : 'Start';
    return 
    div({'className': 'container'}, [
      button({'onClick': onButtonClicked}, buttonText),
      input({'type': 'range', 'onChange': onSliderChanged}),
      languageFilter({'langs': langStream, 'click': setFilter}),
      tweetList({'tweets': tweetStream,  'click': onTweetClicked, 'filter':filter}),
      detail({'detailStream': onTweetClicked.stream}),
    ]);
  }
}
var application = registerComponent(() => new ApplicationComponent());

class TweetListComponent extends StreamComponent {
  
  Stream get _tweetStream => props['tweets'];
  List tweets = [];
  Function get filter => props['filter'];
  var selected;
  
  handleClick(e, t) {
    selected = t;
    props['click'](t);
    redraw();
  }
  
  componentWillMount() {
        
    _tweetStream.listen((tweet) {
      tweets.insert(0, tweet);
      redraw();
    });    
  }
  
  @override
  render() {
    return ul({'className': 'col-sm-5 media-list'}, 
        
      tweets.where(filter).map((t) {
        return 
        li({'key':t['id_str'], 'onClick': (e) => handleClick(e, t), 'className': 'media ' + (t == selected ? 'selected' : ''),}, [
          div({'className': 'media-left'}, 
            img({'className': 'media-object', 'src':t['user']['profile_image_url']})    
          ),
          div({'className': 'media-body'}, [
            h4({'className': 'media-heading'}, t['user']['name']),            
            t['text']
          ])
        ]);    
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

class DetailComponent extends StreamComponent {
  var encoder = new JsonUtf8Encoder(' ');
  
  EventStream get detailStream => props['detailStream'];
  
  
  componentWillMount() {
    detailStream.scan("", highlightDiff).listen(null);
  }
  
  highlightDiff(String prev, Map curr) {
    
    var diffString = UTF8.decode(encoder.convert(curr));
    
    var d = diff(prev, diffString);
    cleanupSemantic(d);
    
    var currList = d.map((d) {
      var a = '';
      switch(d.operation) {
        case DIFF_EQUAL: a = span({'className': 'text-muted'}, d.text); break;
        case DIFF_INSERT: a = span({'className': 'added'}, d.text); break;  
      }
      return a;
    });        
        
    setState({'currList': currList});
    return diffString;
  }

  
  @override
  render() {
    return pre({'key':'dt', 'className': 'col-sm-5 details'}, [
      div({'className':'curr'}, state['currList']),
    ]);
  }
}
var detail = registerComponent(() => new DetailComponent());