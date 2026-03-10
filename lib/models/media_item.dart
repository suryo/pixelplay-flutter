enum MediaType { audio, video }

class MediaItem {
  final String title;
  final String path;
  final String? extension;
  final MediaType type;
  final String? thumbnail;
  final String? artist;
  final String? album;
  final Duration? duration;
  bool isHidden;
  
  MediaItem({
    required this.title,
    required this.path,
    required this.type,
    this.extension,
    this.thumbnail,
    this.artist,
    this.album,
    this.duration,
    this.isHidden = false,
  });

  static MediaType getMediaType(String extension) {
    if (['mp3', 'wav', 'm4a', 'flac', 'aac', 'ogg'].contains(extension.toLowerCase())) {
      return MediaType.audio;
    }
    return MediaType.video;
  }
}
