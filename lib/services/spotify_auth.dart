// lib/services/spotify_auth.dart
/// Spotify OAuth service - Users log in with their Spotify account
/// App uses embedded developer credentials (like Soundiiz)

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// TODO: Replace with your Spotify Developer App credentials
// Create at: https://developer.spotify.com/dashboard
const String _clientId = 'YOUR_CLIENT_ID';
const String _clientSecret = 'YOUR_CLIENT_SECRET';
const String _redirectUri = 'openmusic://callback';

class SpotifyAuth {
  final Dio _dio = Dio();
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  bool get isLoggedIn => _accessToken != null && !_isTokenExpired;
  bool get _isTokenExpired => 
      _tokenExpiry == null || DateTime.now().isAfter(_tokenExpiry!);

  String get _authUrl {
    const scopes = [
      'playlist-read-private',
      'playlist-read-collaborative',
      'user-library-read',
    ];
    
    return Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'scope': scopes.join(' '),
    }).toString();
  }

  /// Open Spotify login in WebView
  Future<bool> login(BuildContext context) async {
    String? authCode;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SpotifyLoginWebView(
          authUrl: _authUrl,
          redirectUri: _redirectUri,
          onCodeReceived: (code) {
            authCode = code;
            Navigator.pop(context);
          },
        ),
      ),
    );

    if (authCode == null) return false;

    return await _exchangeCodeForToken(authCode!);
  }

  Future<bool> _exchangeCodeForToken(String code) async {
    try {
      final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
      
      final response = await _dio.post(
        'https://accounts.spotify.com/api/token',
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
        },
        options: Options(
          headers: {
            'Authorization': 'Basic $credentials',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      _accessToken = response.data['access_token'];
      _refreshToken = response.data['refresh_token'];
      _tokenExpiry = DateTime.now().add(
        Duration(seconds: response.data['expires_in']),
      );

      return true;
    } catch (e) {
      print('Token exchange error: $e');
      return false;
    }
  }

  /// Fetch user's playlists
  Future<List<Map<String, dynamic>>> getUserPlaylists() async {
    if (!isLoggedIn) throw Exception('Not logged in');

    final response = await _dio.get(
      'https://api.spotify.com/v1/me/playlists',
      options: Options(
        headers: {'Authorization': 'Bearer $_accessToken'},
      ),
    );

    return List<Map<String, dynamic>>.from(response.data['items']);
  }

  /// Fetch playlist tracks
  Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId) async {
    if (!isLoggedIn) throw Exception('Not logged in');

    List<Map<String, dynamic>> allTracks = [];
    String? nextUrl = 'https://api.spotify.com/v1/playlists/$playlistId/tracks';

    while (nextUrl != null) {
      final response = await _dio.get(
        nextUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );

      final items = List<Map<String, dynamic>>.from(response.data['items']);
      allTracks.addAll(items);
      nextUrl = response.data['next'];
    }

    return allTracks;
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }
}

class _SpotifyLoginWebView extends StatelessWidget {
  final String authUrl;
  final String redirectUri;
  final Function(String) onCodeReceived;

  const _SpotifyLoginWebView({
    required this.authUrl,
    required this.redirectUri,
    required this.onCodeReceived,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login to Spotify')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(authUrl)),
        onLoadStart: (controller, url) {
          if (url.toString().startsWith(redirectUri)) {
            final code = Uri.parse(url.toString()).queryParameters['code'];
            if (code != null) {
              onCodeReceived(code);
            }
          }
        },
      ),
    );
  }
}
