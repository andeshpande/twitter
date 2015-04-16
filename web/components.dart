import 'package:react/react.dart';
import 'package:frappe/frappe.dart';
import 'dart:convert';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:twitter/util.dart';

class ApplicationComponent extends Component {
  
  EventStream tweetStream;
  EventStream langStream;
  EventStream toggleStream;
  Subject onTweetClicked = new Subject();
  Subject onButtonClicked = new Subject();
  Subject onSliderChanged = new Subject();  
  getInitialState() => {'started': true, 'filter': (data) => true};
  
  
  componentWillMount() {
    
    var _jsonStream = (props['jsonStream'] as EventStream);
    
    
    const MULTIPLIER = 5;        
    
    var sliderDuration = onSliderChanged.stream
       // Map the value of the slider onto a duration 
      .map((e) => new Duration(milliseconds: MULTIPLIER * int.parse(e.target.value)));
    
    // We actually wanted to merge a unit stream with the sliderduration,
    // but the merge method is bugged.
    var duration = new Subject<Duration>()
        // the initial value of the slider
        ..add(new Duration(milliseconds: MULTIPLIER*50))
        ..addStream(sliderDuration)
    ;
    
    // Convert the button events to a boolean toggle stream.
    toggleStream = onButtonClicked.stream.scan(true, (prev, _) => !prev).asBroadcastStream();
    
    var controlledStream = duration.stream
        //change the speed of the stream
        .flatMapLatest((duration) => _jsonStream.sampleEachPeriod(duration))
        // filter out the empty data created by flatmap/sample
        .distinct()
        .where((e) => e.containsKey('lang'))
        // only run when the button allows it
        .when(toggleStream)
        .asBroadcastStream()
      ;
    
    tweetStream = controlledStream.where((Map data) => data.containsKey('created_at'));
    
    langStream = controlledStream.map((data) => data['lang']);
    
  }
  
  componentDidMount(_) => toggleStream.listen((s) => setState({'started':s})); 
  
  @override
  render() {
    var buttonText = state['started'] ? 'Pauze' : 'Start';
      
    return 
    div({'className': 'container'}, [
      button({
        'onClick': onButtonClicked, 
        'className': 'btn btn-default btn-lg'
        }, 
        buttonText
      ),
      input({
        'type': 'range', 
        'onChange': onSliderChanged
      }),
      languageFilter({
        'langs': langStream, 
        'onLanguageSelected': setState
      }),
      tweetList({
        'tweets': tweetStream,
        'onTweetClicked': onTweetClicked,
        'filter': state['filter']
      }),
      detail({
        'detailStream': onTweetClicked.stream
      }),
    ]);
  }
}
var application = registerComponent(() => new ApplicationComponent());

class TweetListComponent extends Component {
  
  EventStream get _tweetStream => props['tweets'];
  Function get filter => props['filter'];
  var selected;
  
  getInitialState() => {'tweets': []};
  
  handleClick(e, t) {
    selected = t;
    props['onTweetClicked'](t);
    redraw();
  }
  
  componentWillMount() {
        
    _tweetStream.scan([], (l,i) => l..insert(0, i))
      .listen((list) => setState({'tweets': list}));    
  }
  
  @override
  render() {
    return ul({'className': 'col-sm-5 media-list'}, 
        
      state['tweets'].where(filter).map((t) {
        return 
        li({'key':t['id_str'], 'onClick': (e) => handleClick(e, t), 'className': 'media ' + (t == selected ? 'selected' : '')}, [
          div({'className': 'media-left'}, 
            img({'className': 'media-object', 'src': t['user']['profile_image_url']})    
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

class LanguageFilterComponent extends Component {
  
  EventStream get _langStream => props['langs'];
  Function get onLanguageSelected => props['onLanguageSelected'];
  
  getInitialState() => {'langs': [{'lang': 'all', 'count': 0}], 'selected': null};
  
  componentDidMount(_) {
    
    _langStream.scan(state['langs'], (list, lang) {
        _add(lang, to:list);
        return list;
      })
      .listen((list) => setState({'langs': list})); 
  }
  
  _add(lang, {to}) {
    var l = to.firstWhere((e) => e['lang'] == lang, orElse: () => null);
    var all = to.firstWhere((e) => e['lang'] == 'all');
    all['count']++;
    if(l != null) {
      l['count']++;
    } else {
      to.add({'lang': lang, 'count': 1});
    }
  }
  
  handleClick(e, lang) {
    onLanguageSelected({'filter': _createFilterFunction(lang)});
    setState({'selected': lang});
  }
  
  _createFilterFunction(lang) => 
      (data) => lang['lang'] == 'all' || data['lang'] == lang['lang'];
  
  @override
  render() {   
    state['langs'].sort((e1,e2) => e2['count'] - e1['count']);
    
    return ul({'key':'ul', 'id': 'langs', 'className': 'col-sm-2 list-group'},
      state['langs'].map((lang) {
        return li({
            'key': lang['lang'], 
            'className': 'list-group-item' + (state['selected'] == lang ? ' selected' : ''),
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

class DetailComponent extends Component {
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