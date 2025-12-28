// lib/services/youtube_dl.dart
/// YouTube download service using youtube_explode_dart

import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';

class YouTubeDownloader {
  final YoutubeExplode _yt;

  YouTubeDownloader() : _yt = YoutubeExplode();

  /// Search YouTube for a track
  Future<List<VideoSearchResult>> searchTrack(String query, {int limit = 5}) async {
    final searchList = await _yt.search.search(query);
    return searchList.take(limit).toList();
  }

  /// Search for a specific track by artist and name
  Future<VideoSearchResult?> findTrack(String artist, String trackName) async {
    final query = '$artist $trackName';
    final results = await searchTrack(query, limit: 3);
    
    if (results.isEmpty) return null;
    
    // Return best match (first result)
    return results.first;
  }

  /// Download audio from YouTube video
  Future<String?> downloadAudio(
    String videoId, {
    required String filename,
    required Function(double) onProgress,
  }) async {
    try {
      // Get audio stream manifest
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();

      // Get download directory
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${appDir.path}/Music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      final filePath = '${musicDir.path}/$filename.m4a';
      final file = File(filePath);

      // Download with progress
      final stream = _yt.videos.streamsClient.get(audioStream);
      final fileStream = file.openWrite();

      final totalBytes = audioStream.size.totalBytes;
      var downloadedBytes = 0;

      await for (final chunk in stream) {
        fileStream.add(chunk);
        downloadedBytes += chunk.length;
        onProgress(downloadedBytes / totalBytes);
      }

      await fileStream.close();
      return filePath;
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  /// Get video info
  Future<Video?> getVideoInfo(String videoId) async {
    try {
      return await _yt.videos.get(videoId);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
