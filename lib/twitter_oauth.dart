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
  String _oauth_nonce;
  String _timestamp;

  OAuthTwitter(params) {
    _oauth_consumer_key = params['oauth_consumer_key'];
    _oauth_consumer_secret = params['oauth_consumer_secret'];
    _oauth_token = params['oauth_token'];
    _oauth_access_secret = params['oauth_access_secret'];
    _oauth_method = params['oauth_method'];
    _oauth_version = params['oauth_version'];

    _oauth_nonce = _create_nonce();
    _timestamp = (new DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
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

  String getAuthorizationHeaders(url, {String method: 'GET'}) {
    print(Uri.encodeFull(url));
    print("GET&https%3A%2F%2Fstream.twitter.com%2F1.1%2Fstatuses%2Fsample.json&");
    // A very crude way to create base string for oauth
    String _base_string =
        "GET&https%3A%2F%2Fstream.twitter.com%2F1.1%2Fstatuses%2Fsample.json&" +
            "oauth_consumer_key%3D" +
            _oauth_consumer_key +
            "%26oauth_nonce%3D" +
            _oauth_nonce +
            "%26oauth_signature_method%3D" +
            _oauth_method +
            "%26oauth_timestamp%3D" +
            _timestamp +
            "%26oauth_token%3D" +
            _oauth_token +
            "%26oauth_version%3D" +
            _oauth_version;

    String _key = Uri.encodeComponent(_oauth_consumer_secret) +
        '&' +
        Uri.encodeComponent(_oauth_access_secret);
    String _oauth_signature = Uri.encodeComponent(
        _computeSignature(UTF8.encode(_key), UTF8.encode(_base_string)));

    var authorization = 'OAuth oauth_consumer_key="' +
        _oauth_consumer_key +
        '", oauth_nonce="' +
        _oauth_nonce +
        '", oauth_signature="' +
        _oauth_signature +
        '", oauth_signature_method="' +
        _oauth_method +
        '", oauth_timestamp="' +
        _timestamp +
        '", oauth_token="' +
        _oauth_token +
        '", oauth_version="' +
        _oauth_version +
        '"';

    return authorization;
  }
}
