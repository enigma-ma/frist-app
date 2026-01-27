
// Defines the data structure for a downloadable stream.
class DownloadableStream {
  final String url; // The direct download URL
  final String quality;
  final String format;
  final int size; // in bytes

  DownloadableStream({
    required this.url,
    required this.quality,
    required this.format,
    required this.size,
  });
}

// Defines the structure for video data extracted from any platform.
class ExtractedVideoData {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final List<DownloadableStream> videoStreams;
  final List<DownloadableStream> audioStreams;

  ExtractedVideoData({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.videoStreams,
    required this.audioStreams,
  });
}

// Abstract class (interface) for all platform-specific extractors.
abstract class Extractor {
  /// Checks if this extractor can handle the given URL.
  bool canHandleUrl(String url);

  /// Extracts all relevant video data from the URL.
  Future<ExtractedVideoData> getVideoData(String url);

  /// Downloads the specified video stream.
  Future<String?> downloadVideoStream(ExtractedVideoData videoData, String quality, Function(double) onProgress);

  /// Downloads the specified audio stream.
  Future<String?> downloadAudioStream(ExtractedVideoData videoData, Function(double) onProgress);
}

// A factory to get the correct extractor for a given URL.
class ExtractorFactory {
  final List<Extractor> _extractors;

  ExtractorFactory(this._extractors);

  Extractor? getExtractorForUrl(String url) {
    try {
      return _extractors.firstWhere((extractor) => extractor.canHandleUrl(url));
    } catch (e) {
      // If no extractor is found, return null.
      return null;
    }
  }
}
