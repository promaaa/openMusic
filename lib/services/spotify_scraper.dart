// lib/services/spotify_scraper.dart
/// Spotify playlist scraper - No API key required
/// Scrapes public playlists from Spotify embed pages

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

class SpotifyTrack {
  final String id;
  final String name;
  final String artist;
  final String? albumName;
  final String? imageUrl;
  final int? durationMs;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    this.albumName,
    this.imageUrl,
    this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artist': artist,
    'albumName': albumName,
    'imageUrl': imageUrl,
    'durationMs': durationMs,
  };
}

class SpotifyPlaylist {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<SpotifyTrack> tracks;

  SpotifyPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.tracks,
  });
}

class SpotifyScraper {
  final Dio _dio;

  SpotifyScraper() : _dio = Dio() {
    _dio.options.headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'text/html,application/xhtml+xml',
    };
  }

  /// Extract playlist ID from various Spotify URL formats
  String? extractPlaylistId(String url) {
    // Formats: 
    // https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M
    // spotify:playlist:37i9dQZF1DXcBWIGoYBM5M
    final regex = RegExp(r'playlist[:/]([a-zA-Z0-9]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Fetch playlist metadata and tracks from Spotify embed page
  Future<SpotifyPlaylist?> fetchPlaylist(String playlistUrl) async {
    final playlistId = extractPlaylistId(playlistUrl);
    if (playlistId == null) {
      throw Exception('Invalid Spotify playlist URL');
    }

    // Use embed endpoint (public, no auth required)
    final embedUrl = 'https://open.spotify.com/embed/playlist/$playlistId';
    
    try {
      final response = await _dio.get(embedUrl);
      return _parseEmbedPage(response.data, playlistId);
    } catch (e) {
      throw Exception('Failed to fetch playlist: $e');
    }
  }

  SpotifyPlaylist? _parseEmbedPage(String html, String playlistId) {
    final document = html_parser.parse(html);
    
    // Extract playlist name from title or meta tags
    final title = document.querySelector('title')?.text ?? 'Playlist';
    final name = title.replaceAll(' | Spotify', '').trim();
    
    // Try to find track data in script tags (Spotify embeds include JSON data)
    final scripts = document.querySelectorAll('script');
    List<SpotifyTrack> tracks = [];
    
    for (final script in scripts) {
      final content = script.text;
      if (content.contains('Spotify.Entity') || content.contains('"tracks"')) {
        // Parse track data from embedded JSON
        tracks = _extractTracksFromScript(content);
        break;
      }
    }
    
    return SpotifyPlaylist(
      id: playlistId,
      name: name,
      tracks: tracks,
    );
  }

  List<SpotifyTrack> _extractTracksFromScript(String scriptContent) {
    List<SpotifyTrack> tracks = [];
    
    // Look for track patterns in the script
    // This is a simplified parser - real implementation would use JSON parsing
    final trackPattern = RegExp(
      r'"name"\s*:\s*"([^"]+)".*?"artists".*?"name"\s*:\s*"([^"]+)"',
      multiLine: true,
    );
    
    for (final match in trackPattern.allMatches(scriptContent)) {
      tracks.add(SpotifyTrack(
        id: 'track_${tracks.length}',
        name: match.group(1) ?? 'Unknown',
        artist: match.group(2) ?? 'Unknown',
      ));
    }
    
    return tracks;
  }
}
