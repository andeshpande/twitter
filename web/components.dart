import 'package:react_stream/react_stream.dart';
import 'package:react/react.dart' as react;
import 'dart:async';
import 'dart:convert';

class ApplicationComponent extends StreamComponent {
  
  Stream get _jsonStream => props['jsonStream'];
  
  Stream _tweetStream;
  Stream _langStream;
  var f = (data) => true;
  
  componentWillMount() {
    _tweetStream = _jsonStream.where((Map data) => data.containsKey('created_at'));
    
    _langStream = _tweetStream.map((data) => data['lang']);
  }
  
  filter(f) {
    this.f = f;
    redraw();
  }

  @override
  render() {
    var encoder = new JsonUtf8Encoder(' ');
    return react.div({'className': 'container'}, [
      languageFilter({'langs': _langStream, 'click': filter}),
      tweetList({'tweets': _tweetStream, 'click': setState, 'filter':f}),
      react.pre({'className': 'col-sm-5'}, UTF8.decode(encoder.convert(state))),
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
  }
  
  get stateStream => props['tweets'];
  
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
  
  componentWillMount() {
    _langStream.listen((lang) {
      
      var l = langs.firstWhere((e) => e['lang'] == lang, orElse: () => null);
      var all = langs.firstWhere((e) => e['lang'] == 'all');
      all['count']++;
      if(l != null) {
        l['count']++;
      } else {
        langs.add({'lang': lang, 'count': 1});
      }
      redraw();
    });    
  }
  
  var selected;
  handleClick(e, lang) {
    selected = lang;
    props['click']((data) => lang['lang'] == 'all' || data['lang'] == lang['lang']);
    redraw();
  }
  
  @override
  render() {   
    langs.sort((e1,e2) => e2['count'] - e1['count']);
    
    return react.ul({'id': 'langs', 'className': 'col-sm-2 list-group'},
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