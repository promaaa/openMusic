// lib/ui/playlist_page.dart
/// Playlist view with download functionality

import 'package:flutter/material.dart';
import '../services/spotify_scraper.dart';
import '../services/youtube_dl.dart';

class PlaylistPage extends StatefulWidget {
  final SpotifyPlaylist playlist;

  const PlaylistPage({super.key, required this.playlist});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final _downloader = YouTubeDownloader();
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloaded = {};
  bool _isDownloadingAll = false;

  Future<void> _downloadTrack(SpotifyTrack track) async {
    setState(() => _downloadProgress[track.id] = 0.0);

    try {
      // Search YouTube for the track
      final result = await _downloader.findTrack(track.artist, track.name);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find: ${track.name}')),
        );
        setState(() => _downloadProgress.remove(track.id));
        return;
      }

      // Download audio
      final filename = '${track.artist} - ${track.name}'.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      await _downloader.downloadAudio(
        result.id.value,
        filename: filename,
        onProgress: (progress) {
          setState(() => _downloadProgress[track.id] = progress);
        },
      );

      setState(() {
        _downloadProgress.remove(track.id);
        _downloaded.add(track.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded: ${track.name}')),
      );
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
      body: ListView.builder(
        itemCount: widget.playlist.tracks.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final track = widget.playlist.tracks[index];
          final progress = _downloadProgress[track.id];
          final isDownloaded = _downloaded.contains(track.id);

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
            trailing: _buildTrailingWidget(track, progress, isDownloaded),
          );
        },
      ),
    );
  }

  Widget _buildTrailingWidget(SpotifyTrack track, double? progress, bool isDownloaded) {
    if (isDownloaded) {
      return const Icon(Icons.check_circle, color: Colors.green);
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
    _downloader.dispose();
    super.dispose();
  }
}
