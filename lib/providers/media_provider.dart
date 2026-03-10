import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:pixelplay/models/media_item.dart';

class MediaProvider extends ChangeNotifier {
  final Player player = Player();
  late VideoController videoController;
  static const _pipChannel = MethodChannel('pixelplay/pip');
  
  List<MediaItem> _playlist = [];
  List<MediaItem> _allScannedItems = []; 
  String _currentQueueName = 'Library Queue';
  Map<String, List<String>> _customPlaylists = {}; 
  Set<String> _hiddenPaths = {};
  bool _showHidden = false;
  
  MediaItem? _currentItem;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<double> equalizerGains = List.filled(10, 0.0);
  bool _isPiPActive = false;

  List<MediaItem> get playlist => _playlist.where((item) => _showHidden || !item.isHidden).toList();
  String get currentQueueName => _currentQueueName;
  MediaItem? get currentItem => _currentItem;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get showHidden => _showHidden;
  Map<String, List<String>> get customPlaylists => _customPlaylists;
  List<MediaItem> get allScannedItems => _allScannedItems;
  bool get isPiPActive => _isPiPActive;

  Map<String, List<MediaItem>> get folders {
    final Map<String, List<MediaItem>> folderMap = {};
    for (var item in playlist) {
      final parentPath = File(item.path).parent.path;
      if (!folderMap.containsKey(parentPath)) {
        folderMap[parentPath] = [];
      }
      folderMap[parentPath]!.add(item);
    }
    return folderMap;
  }

  Map<String, List<MediaItem>> get albums {
    final Map<String, List<MediaItem>> albumMap = {};
    for (var item in playlist) {
      final albumName = item.album ?? 'Unknown Album';
      if (!albumMap.containsKey(albumName)) {
        albumMap[albumName] = [];
      }
      albumMap[albumName]!.add(item);
    }
    return albumMap;
  }

  Map<String, List<MediaItem>> get artists {
    final Map<String, List<MediaItem>> artistMap = {};
    for (var item in playlist) {
      final artistName = item.artist ?? 'Unknown Artist';
      if (!artistMap.containsKey(artistName)) {
        artistMap[artistName] = [];
      }
      artistMap[artistName]!.add(item);
    }
    return artistMap;
  }

  MediaProvider() {
    videoController = VideoController(player);
    _initListeners();
    _loadPreferences();
    autoScanMedia();
    
    _pipChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPiPModeChanged') {
        _isPiPActive = call.arguments as bool;
        notifyListeners();
      }
    });
  }

  void _initListeners() {
    player.stream.playing.listen((playing) {
      _isPlaying = playing;
      _syncPlaybackToNative();
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

    Map<String, MediaItem> uniqueScanned = {};
    for (var path in paths) {
      List<AssetEntity> entities = await path.getAssetListRange(start: 0, end: 1000);
      for (var entity in entities) {
        if (entity.type == AssetType.image) continue;

        File? file = await entity.file;
        if (file != null && !uniqueScanned.containsKey(file.path)) {
          final ext = file.path.split('.').last;
          final isHidden = _hiddenPaths.contains(file.path) || file.path.split('/').last.startsWith('.');
          uniqueScanned[file.path] = MediaItem(
            title: entity.title ?? file.path.split('/').last,
            path: file.path,
            extension: ext,
            type: entity.type == AssetType.audio ? MediaType.audio : MediaType.video,
            isHidden: isHidden,
          );
        }
      }
    }
    
    _allScannedItems = uniqueScanned.values.toList();
    _playlist = List.from(_allScannedItems);
    _currentQueueName = 'Library Queue';
    notifyListeners();
  }

  void loadPlaylist(String name) {
    if (_customPlaylists.containsKey(name)) {
      final paths = _customPlaylists[name]!;
      _playlist = _allScannedItems.where((item) => paths.contains(item.path)).toList();
      _currentQueueName = name;
      notifyListeners();
    }
  }

  void resetToLibrary() {
    _playlist = List.from(_allScannedItems);
    _currentQueueName = 'Library Queue';
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
    final uri = item.path.startsWith('http') ? item.path : Uri.file(item.path).toString();
    player.open(Media(uri));
    player.play();
    _syncPlaybackToNative();
    notifyListeners();
  }

  void _syncPlaybackToNative() {
    _pipChannel.invokeMethod('updatePlaybackStatus', {
      'isPlaying': _isPlaying && _currentItem != null,
      'mediaType': _currentItem?.type == MediaType.video ? 'video' : 'audio',
    });
  }

  void togglePlayback() {
    if (player.state.playing) {
      player.pause();
    } else {
      if (_currentItem == null && _playlist.isNotEmpty) {
        playItem(_playlist.first);
      } else {
        player.play();
      }
    }
    _syncPlaybackToNative();
  }

  void seek(Duration position) {
    player.seek(position);
  }

  void playAfterCurrent(MediaItem item) {
    if (_currentItem == null) {
      playItem(item);
      return;
    }
    final index = _playlist.indexOf(_currentItem!);
    if (!_playlist.contains(item)) {
      _playlist.insert(index + 1, item);
    } else {
      final oldIndex = _playlist.indexOf(item);
      _playlist.removeAt(oldIndex);
      final newIndex = _playlist.indexOf(_currentItem!);
      _playlist.insert(newIndex + 1, item);
    }
    notifyListeners();
  }

  void saveQueueAsPlaylist(String name) {
    _customPlaylists[name] = _playlist.map((e) => e.path).toSet().toList();
    _savePreferences();
    notifyListeners();
  }

  void skipNext() {
    _playNext();
  }

  void playPrevious() {
    final currentList = playlist;
    if (_currentItem == null || currentList.isEmpty) return;
    int index = currentList.indexWhere((e) => e.path == _currentItem!.path);
    if (index > 0) {
      playItem(currentList[index - 1]);
    } else {
      // Loop to end or just stay at beginning
       playItem(currentList.last);
    }
  }

  void _playNext() {
    final currentList = playlist;
    if (_currentItem == null || currentList.isEmpty) return;
    int index = currentList.indexWhere((e) => e.path == _currentItem!.path);
    if (index < currentList.length - 1) {
      playItem(currentList[index + 1]);
    } else {
      // Loop to beginning if at end? Optional. Let's loop.
      playItem(currentList.first);
    }
  }

  void removeMedia(MediaItem item) {
    _playlist.removeWhere((e) => e.path == item.path);
    _allScannedItems.removeWhere((e) => e.path == item.path);
    
    // Also remove from all custom playlists
    _customPlaylists.forEach((name, paths) {
      paths.remove(item.path);
    });

    if (_currentItem?.path == item.path) {
      player.stop();
      _currentItem = null;
    }
    _savePreferences();
    notifyListeners();
  }

  void updateMediaMetadata(MediaItem item, {String? title, String? artist, String? album}) {
    final updateInList = (List<MediaItem> list) {
       final idx = list.indexWhere((e) => e.path == item.path);
       if(idx != -1) {
          list[idx] = MediaItem(
            title: title ?? list[idx].title,
            path: list[idx].path,
            type: list[idx].type,
            extension: list[idx].extension,
            thumbnail: list[idx].thumbnail,
            artist: artist ?? list[idx].artist,
            album: album ?? list[idx].album,
            duration: list[idx].duration,
            isHidden: list[idx].isHidden,
          );
       }
    };
    
    updateInList(_playlist);
    updateInList(_allScannedItems);
    
    if (_currentItem?.path == item.path) {
       _currentItem = _allScannedItems.firstWhere((e) => e.path == item.path);
    }
    
    _savePreferences();
    notifyListeners();
  }

  void setRate(double rate) {
    player.setRate(rate);
    notifyListeners();
  }

  void setPitch(double pitch) {
    player.setPitch(pitch);
    notifyListeners();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
