import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixelplay/models/media_item.dart';

class MediaProvider extends ChangeNotifier {
  final Player player = Player();
  late VideoController videoController;
  
  List<MediaItem> _playlist = [];
  Map<String, List<String>> _customPlaylists = {}; // Name -> List of paths
  Set<String> _hiddenPaths = {};
  bool _showHidden = false;
  
  MediaItem? _currentItem;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Equalizer gains (31Hz to 16kHz)
  List<double> equalizerGains = List.filled(10, 0.0);

  List<MediaItem> get playlist => _playlist.where((item) => _showHidden || !item.isHidden).toList();
  MediaItem? get currentItem => _currentItem;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get showHidden => _showHidden;
  Map<String, List<String>> get customPlaylists => _customPlaylists;

  MediaProvider() {
    videoController = VideoController(player);
    _initListeners();
    _loadPreferences();
    autoScanMedia();
  }

  void _initListeners() {
    player.stream.playing.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });
    player.stream.position.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    player.stream.duration.listen((dur) {
      _duration = dur;
      notifyListeners();
    });
    player.stream.completed.listen((completed) {
      if (completed) {
        _playNext();
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showHidden = prefs.getBool('showHidden') ?? false;
    _hiddenPaths = (prefs.getStringList('hiddenPaths') ?? []).toSet();
    
    // Load playlists
    String? playlistsJson = prefs.getString('customPlaylists');
    if (playlistsJson != null) {
      Map<String, dynamic> decoded = jsonDecode(playlistsJson);
      _customPlaylists = decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
    }
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showHidden', _showHidden);
    await prefs.setStringList('hiddenPaths', _hiddenPaths.toList());
    await prefs.setString('customPlaylists', jsonEncode(_customPlaylists));
  }

  Future<void> autoScanMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) return;

    // Explicitly request only Audio and Video
    List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.audio | RequestType.video,
    );

    List<MediaItem> scannedItems = [];
    for (var path in paths) {
      List<AssetEntity> entities = await path.getAssetListRange(start: 0, end: 1000);
      for (var entity in entities) {
        // Skip if for some reason it's an image
        if (entity.type == AssetType.image) continue;

        File? file = await entity.file;
        if (file != null) {
          final ext = file.path.split('.').last;
          final isHidden = _hiddenPaths.contains(file.path) || file.path.split('/').last.startsWith('.');
          scannedItems.add(MediaItem(
            title: entity.title ?? file.path.split('/').last,
            path: file.path,
            extension: ext,
            type: entity.type == AssetType.audio ? MediaType.audio : MediaType.video,
            isHidden: isHidden,
          ));
        }
      }
    }
    
    _playlist = scannedItems;
    notifyListeners();
  }

  void toggleShowHidden() {
    _showHidden = !_showHidden;
    _savePreferences();
    notifyListeners();
  }

  void hideItem(MediaItem item) {
    item.isHidden = true;
    _hiddenPaths.add(item.path);
    _savePreferences();
    notifyListeners();
  }

  void unhideItem(MediaItem item) {
    item.isHidden = false;
    _hiddenPaths.remove(item.path);
    _savePreferences();
    notifyListeners();
  }

  void updateEqualizer(int index, double gain) {
    equalizerGains[index] = gain;
    // Note: setProperty('af', ...) is not available in the surface of Player in v1.2.6
    // We keep the UI state but disable the filter application to avoid compile errors
    // String filter = 'equalizer=' + 
    //   equalizerGains.asMap().entries.map((e) => 'f=${[31,62,125,250,500,1000,2000,4000,8000,16000][e.key]}:width_type=o:w=1:g=${e.value}').join(':');
    
    // player.setProperty('af', filter);
    notifyListeners();
  }

  // Playlist Management
  void createPlaylist(String name) {
    if (!_customPlaylists.containsKey(name)) {
      _customPlaylists[name] = [];
      _savePreferences();
      notifyListeners();
    }
  }

  void addToPlaylist(String playlistName, MediaItem item) {
    if (_customPlaylists.containsKey(playlistName)) {
      if (!_customPlaylists[playlistName]!.contains(item.path)) {
        _customPlaylists[playlistName]!.add(item.path);
        _savePreferences();
        notifyListeners();
      }
    }
  }

  void removeFromPlaylist(String playlistName, String itemPath) {
    if (_customPlaylists.containsKey(playlistName)) {
      _customPlaylists[playlistName]!.remove(itemPath);
      _savePreferences();
      notifyListeners();
    }
  }

  void deletePlaylist(String name) {
    if (_customPlaylists.containsKey(name)) {
      _customPlaylists.remove(name);
      _savePreferences();
      notifyListeners();
    }
  }

  void renamePlaylist(String oldName, String newName) {
    if (_customPlaylists.containsKey(oldName) && newName.isNotEmpty && oldName != newName) {
      _customPlaylists[newName] = _customPlaylists[oldName]!;
      _customPlaylists.remove(oldName);
      _savePreferences();
      notifyListeners();
    }
  }

  Future<void> pickMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'mp4', 'mkv', 'avi', 'mov', 'flac', 'm4a'],
    );

    if (result != null) {
      List<MediaItem> newItems = result.files.map((file) {
        final ext = file.extension ?? '';
        return MediaItem(
          title: file.name,
          path: file.path!,
          extension: ext,
          type: MediaItem.getMediaType(ext),
        );
      }).toList();

      for (var item in newItems) {
        if (!_playlist.any((e) => e.path == item.path)) {
          _playlist.add(item);
        }
      }
      notifyListeners();
      
      if (_currentItem == null && _playlist.isNotEmpty) {
        playItem(_playlist.first);
      }
    }
  }

  void playItem(MediaItem item) {
    _currentItem = item;
    player.open(Media(item.path));
    player.play();
    notifyListeners();
  }

  void togglePlayback() {
    if (player.state.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void seek(Duration position) {
    player.seek(position);
  }

  void _playNext() {
    final currentList = playlist;
    if (_currentItem == null || currentList.isEmpty) return;
    int index = currentList.indexOf(_currentItem!);
    if (index < currentList.length - 1) {
      playItem(currentList[index + 1]);
    }
  }

  void removeMedia(MediaItem item) {
    _playlist.remove(item);
    if (_currentItem == item) {
      player.stop();
      _currentItem = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
