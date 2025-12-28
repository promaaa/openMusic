// lib/services/annas_archive.dart
/// Anna's Archive service - Primary download source
/// Falls back to YouTube if track not found

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

class AnnasArchiveService {
  final Dio _dio;
  
  // Anna's Archive base URL
  static const String _baseUrl = 'https://annas-archive.org';
  
  AnnasArchiveService() : _dio = Dio() {
    _dio.options.headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'text/html,application/xhtml+xml',
    };
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Search for a track on Anna's Archive
  /// Returns download URL if found, null otherwise
  Future<TrackSearchResult?> searchTrack(String artist, String trackName) async {
    try {
      // Build search query
      final query = '$artist $trackName';
      final searchUrl = '$_baseUrl/search?q=${Uri.encodeComponent(query)}&index=music';
      
      final response = await _dio.get(searchUrl);
      return _parseSearchResults(response.data, artist, trackName);
    } catch (e) {
      print('Anna\'s Archive search error: $e');
      return null;
    }
  }

  TrackSearchResult? _parseSearchResults(String html, String artist, String trackName) {
    final document = html_parser.parse(html);
    
    // Look for result containers
    final results = document.querySelectorAll('div.flex.pt-3.pb-3.border-b');
    
    for (final result in results) {
      final titleElem = result.querySelector('a.line-clamp-\\[3\\]');
      if (titleElem == null) continue;
      
      final title = titleElem.text.toLowerCase();
      final link = titleElem.attributes['href'];
      
      // Check if this result matches our track
      if (title.contains(artist.toLowerCase()) && 
          title.contains(trackName.toLowerCase())) {
        return TrackSearchResult(
          title: titleElem.text,
          link: '$_baseUrl$link',
          source: 'annas_archive',
        );
      }
    }
    
    return null;
  }

  /// Get download mirrors for a track
  Future<List<String>> getDownloadMirrors(String trackPageUrl) async {
    try {
      final response = await _dio.get(trackPageUrl);
      return _parseDownloadMirrors(response.data);
    } catch (e) {
      print('Error fetching mirrors: $e');
      return [];
    }
  }

  List<String> _parseDownloadMirrors(String html) {
    final document = html_parser.parse(html);
    final mirrors = <String>[];
    
    // Look for slow download links
    final slowDownloads = document.querySelectorAll('a[href*="/slow_download/"]');
    for (final link in slowDownloads) {
      final href = link.attributes['href'];
      if (href != null) {
        mirrors.add('$_baseUrl$href');
      }
    }
    
    // Look for fast download links
    final fastDownloads = document.querySelectorAll('a[href*="/fast_download/"]');
    for (final link in fastDownloads) {
      final href = link.attributes['href'];
      if (href != null) {
        mirrors.add('$_baseUrl$href');
      }
    }
    
    return mirrors;
  }

  /// Check if Anna's Archive music search is available
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.head(_baseUrl);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class TrackSearchResult {
  final String title;
  final String link;
  final String source;

  TrackSearchResult({
    required this.title,
    required this.link,
    required this.source,
  });
}
