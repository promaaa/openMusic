// lib/services/download_manager.dart
/// Unified download manager
/// Priority: Anna's Archive → YouTube

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'annas_archive.dart';
import 'youtube_dl.dart';

enum DownloadSource { annasArchive, youtube }

class DownloadResult {
  final bool success;
  final String? filePath;
  final DownloadSource? source;
  final String? error;

  DownloadResult({
    required this.success,
    this.filePath,
    this.source,
    this.error,
  });
}

class DownloadManager {
  final AnnasArchiveService _annasArchive;
  final YouTubeDownloader _youtube;
  final Dio _dio;

  DownloadManager()
      : _annasArchive = AnnasArchiveService(),
        _youtube = YouTubeDownloader(),
        _dio = Dio();

  /// Download a track - tries Anna's Archive first, falls back to YouTube
  Future<DownloadResult> downloadTrack({
    required String artist,
    required String trackName,
    required Function(double) onProgress,
    String? albumArt,
  }) async {
    final filename = '${artist} - ${trackName}'.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // 1. Try Anna's Archive first
    print('🔍 Searching Anna\'s Archive for: $artist - $trackName');
    try {
      final aaResult = await _annasArchive.searchTrack(artist, trackName);
      
      if (aaResult != null) {
        print('✅ Found on Anna\'s Archive: ${aaResult.title}');
        
        // Get download mirrors
        final mirrors = await _annasArchive.getDownloadMirrors(aaResult.link);
        
        if (mirrors.isNotEmpty) {
          // Try to download from first available mirror
          final filePath = await _downloadFromMirror(
            mirrors.first,
            filename,
            onProgress,
          );
          
          if (filePath != null) {
            return DownloadResult(
              success: true,
              filePath: filePath,
              source: DownloadSource.annasArchive,
            );
          }
        }
      }
    } catch (e) {
      print('⚠️ Anna\'s Archive error: $e');
    }

    // 2. Fallback to YouTube
    print('🔍 Searching YouTube for: $artist - $trackName');
    try {
      final ytResult = await _youtube.findTrack(artist, trackName);
      
      if (ytResult != null) {
        print('✅ Found on YouTube: ${ytResult.title}');
        
        final filePath = await _youtube.downloadAudio(
          ytResult.id.value,
          filename: filename,
          onProgress: onProgress,
        );
        
        if (filePath != null) {
          return DownloadResult(
            success: true,
            filePath: filePath,
            source: DownloadSource.youtube,
          );
        }
      }
    } catch (e) {
      print('⚠️ YouTube error: $e');
    }

    // 3. Both failed
    return DownloadResult(
      success: false,
      error: 'Could not find track on Anna\'s Archive or YouTube',
    );
  }

  Future<String?> _downloadFromMirror(
    String mirrorUrl,
    String filename,
    Function(double) onProgress,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${appDir.path}/Music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      final filePath = '${musicDir.path}/$filename.mp3';

      await _dio.download(
        mirrorUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      return filePath;
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  void dispose() {
    _youtube.dispose();
  }
}
