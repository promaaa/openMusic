// lib/ui/home_page.dart
/// Home page with playlist URL input

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/spotify_scraper.dart';
import 'playlist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _urlController = TextEditingController();
  final _scraper = SpotifyScraper();
  bool _isLoading = false;
  String? _error;

  Future<void> _fetchPlaylist() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a Spotify playlist URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final playlist = await _scraper.fetchPlaylist(url);
      if (playlist != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistPage(playlist: playlist),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _urlController.text = data!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Logo & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.music_note, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OpenMusic',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Download Spotify Playlists',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Instruction
              const Text(
                'Paste your Spotify playlist link',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              
              // URL Input
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'https://open.spotify.com/playlist/...',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: _pasteFromClipboard,
                    tooltip: 'Paste from clipboard',
                  ),
                ),
                onSubmitted: (_) => _fetchPlaylist(),
              ),
              
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Fetch Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _fetchPlaylist,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Fetch Playlist', style: TextStyle(fontSize: 16)),
                ),
              ),
              
              const Spacer(),
              
              // Footer
              Center(
                child: Text(
                  'No Spotify account required',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
