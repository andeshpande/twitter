library twitter.oauth;

import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart' as crypto;

class OAuthTwitter {
  
  String _oauth_consumer_key;
  String _oauth_consumer_secret;
  String _oauth_token;
  String _oauth_access_secret;
  String _oauth_method;
  String _oauth_version;

  OAuthTwitter(params) {    
    _oauth_consumer_key = params['oauth_consumer_key'];
    _oauth_consumer_secret = params['oauth_consumer_secret'];
    _oauth_token = params['oauth_token'];
    _oauth_access_secret = params['oauth_access_secret'];
    _oauth_method = params['oauth_method'];
    _oauth_version = params['oauth_version'];
  }

  String _create_nonce() {
    math.Random rnd = new math.Random();
    List<int> values = new List<int>.generate(32, (i) => rnd.nextInt(256));
    var oauth_nonce = crypto.CryptoUtils
        .bytesToBase64(values)
        .replaceAll(new RegExp('[=/+]'), '');
    return oauth_nonce;
  }

  String _computeSignature(List<int> key, List<int> signatureBase) {
    var mac = new crypto.HMAC(new crypto.SHA1(), key);
    mac.add(signatureBase);
    return crypto.CryptoUtils.bytesToBase64(mac.close());
  }

  String getAuthorizationHeaders(url, {String method: 'GET', Map params: null}) {
    var _oauth_nonce = _create_nonce();
    var _timestamp = (new DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    
    if(params == null) params = {};
    var paramStringList = [];
    params.addAll({
      'oauth_consumer_key': _oauth_consumer_key,
      'oauth_nonce': _oauth_nonce,
      'oauth_signature_method': _oauth_method,
      'oauth_timestamp': _timestamp,
      'oauth_token': _oauth_token,
      'oauth_version': _oauth_version
    });
    params.forEach((k,v) => paramStringList.add('$k=$v'));
    paramStringList.sort();
    
    var _base_string = method+'&'+Uri.encodeComponent(url)+'&'+
      Uri.encodeComponent(paramStringList.join('&'));

    String _key = Uri.encodeComponent(_oauth_consumer_secret) +
        '&' +
        Uri.encodeComponent(_oauth_access_secret);
    
    String _oauth_signature = Uri.encodeComponent(
        _computeSignature(UTF8.encode(_key), UTF8.encode(_base_string)));

    var authorization = 'OAuth ' +
        'oauth_consumer_key="$_oauth_consumer_key", ' +
        'oauth_nonce="$_oauth_nonce", ' +
        'oauth_signature="$_oauth_signature", ' +
        'oauth_signature_method="$_oauth_method", ' +
        'oauth_timestamp="$_timestamp", ' +
        'oauth_token="$_oauth_token", ' +
        'oauth_version="$_oauth_version"';

    return authorization;
  }
}