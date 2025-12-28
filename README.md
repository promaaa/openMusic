# 🎵 OpenMusic

Download your Spotify playlists offline.

**No Spotify Developer account needed** — just login with your regular Spotify account, select your playlists, and download them via YouTube.

Inspired by [Openlib](https://github.com/dstark5/Openlib).

---

## Features

- 🔐 **Spotify OAuth Login** — Use your normal Spotify account
- 📋 **Import Playlists** — Access all your playlists
- ⬇️ **Download via YouTube** — High quality audio
- 📱 **Mobile App** — Android & iOS

## How It Works

```
1. Login with Spotify
        ↓
2. Select a playlist
        ↓
3. Download tracks via YouTube
        ↓
4. Listen offline
```

## Installation

### Prerequisites
- Flutter 3.x
- Android Studio / Xcode

### Build

```bash
git clone https://github.com/promaaa/openMusic.git
cd openMusic
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── services/
│   ├── spotify_auth.dart    # OAuth login
│   ├── spotify_scraper.dart # Public playlist scraping
│   └── youtube_dl.dart      # YouTube download
└── ui/
    ├── home_page.dart
    └── playlist_page.dart
```

## Configuration

For developers: Add your Spotify credentials in `lib/services/spotify_auth.dart`:

```dart
const String _clientId = 'YOUR_CLIENT_ID';
const String _clientSecret = 'YOUR_CLIENT_SECRET';
```

Create a Spotify app at [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard).

## License

MIT
