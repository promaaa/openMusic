// lib/ui/playlist_page.dart
/// Playlist view with download - Anna's Archive first, YouTube fallback

import 'package:flutter/material.dart';
import '../services/spotify_scraper.dart';
import '../services/download_manager.dart';

class PlaylistPage extends StatefulWidget {
  final SpotifyPlaylist playlist;

  const PlaylistPage({super.key, required this.playlist});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final _downloadManager = DownloadManager();
  final Map<String, double> _downloadProgress = {};
  final Map<String, DownloadSource> _downloadSources = {};
  final Set<String> _downloaded = {};
  bool _isDownloadingAll = false;

  Future<void> _downloadTrack(SpotifyTrack track) async {
    setState(() => _downloadProgress[track.id] = 0.0);

    try {
      final result = await _downloadManager.downloadTrack(
        artist: track.artist,
        trackName: track.name,
        onProgress: (progress) {
          setState(() => _downloadProgress[track.id] = progress);
        },
      );

      if (result.success) {
        setState(() {
          _downloadProgress.remove(track.id);
          _downloaded.add(track.id);
          if (result.source != null) {
            _downloadSources[track.id] = result.source!;
          }
        });

        final sourceIcon = result.source == DownloadSource.annasArchive ? '📚' : '🎥';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$sourceIcon Downloaded: ${track.name}')),
        );
      } else {
        setState(() => _downloadProgress.remove(track.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${result.error ?? "Download failed"}')),
        );
      }
    } catch (e) {
      setState(() => _downloadProgress.remove(track.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _downloadAll() async {
    setState(() => _isDownloadingAll = true);
    
    for (final track in widget.playlist.tracks) {
      if (!_downloaded.contains(track.id)) {
        await _downloadTrack(track);
      }
    }
    
    setState(() => _isDownloadingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          IconButton(
            icon: _isDownloadingAll
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _isDownloadingAll ? null : _downloadAll,
            tooltip: 'Download All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Download priority info
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade900,
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📚 Anna\'s Archive (primary) → �� YouTube (fallback)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Track list
          Expanded(
            child: ListView.builder(
              itemCount: widget.playlist.tracks.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final track = widget.playlist.tracks[index];
                final progress = _downloadProgress[track.id];
                final isDownloaded = _downloaded.contains(track.id);
                final source = _downloadSources[track.id];

                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: track.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(track.imageUrl!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.music_note),
                  ),
                  title: Text(
                    track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  trailing: _buildTrailingWidget(track, progress, isDownloaded, source),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingWidget(
    SpotifyTrack track,
    double? progress,
    bool isDownloaded,
    DownloadSource? source,
  ) {
    if (isDownloaded) {
      final icon = source == DownloadSource.annasArchive 
          ? '📚' 
          : '🎥';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon),
          const SizedBox(width: 4),
          const Icon(Icons.check_circle, color: Colors.green),
        ],
      );
    }
    
    if (progress != null) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
    }
    
    return IconButton(
      icon: const Icon(Icons.download_outlined),
      onPressed: () => _downloadTrack(track),
    );
  }

  @override
  void dispose() {
    _downloadManager.dispose();
    super.dispose();
  }
}
