//import 'package:react_stream/react_stream.dart';
import 'package:react/react.dart' as react;
import 'dart:async';

class ApplicationComponent extends react.Component {
  
  Stream get _jsonStream => props['jsonStream'];
  
  Stream _tweetStream;
  Stream _langStream;
  
  componentDidMount(rootNode) {
    _tweetStream = _jsonStream.where((Map data) => data.containsKey('created_at'));
    _langStream = _tweetStream.map((data) => data['lang']);          
  }
  
//  ApplicationComponent() {
//    
//    onMounted.listen((_) {
//    });
//  }
  
  @override
  render() {
    react.div({'className': 'container'}, [
      tweetList({'tweets' : _tweetStream}),
      languageFilter({'langs': _langStream}),
    ]);
  }
}
var application = react.registerComponent(() => new ApplicationComponent());

class TweetListComponent extends react.Component {
  
  Stream get _tweets => props['tweets'];
  List tweetList = [];
  
  componentDidMount(rootNode) {
    _tweets.listen((tweet) {
      tweetList.add(tweet);
      render();
    });    
  }
//  
//  TweetListComponent() {
//  }
  
  @override
  render() {
    react.div({'id': 'created', 'className': 'col-sm-5'}, 
      tweetList.map((t) {
        return react.pre({}, [t['text']]);    
      })
    );
  }
}
var tweetList = react.registerComponent(() => new TweetListComponent());

class LanguageFilterComponent extends react.Component {
  
  get _langs => props['langs'];
  
  @override
  render() {
    react.ul({'id': 'langs', 'className': 'col-sm-2 list-group'},
      [] // foreach language
    ); 
  }
}
var languageFilter = react.registerComponent(() => new LanguageFilterComponent());