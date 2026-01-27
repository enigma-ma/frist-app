import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'extractor_service.dart';

class YouTubeExtractor implements Extractor {
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  @override
  bool canHandleUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  @override
  Future<ExtractedVideoData> getVideoData(String url) async {
    final videoId = VideoId(url);
    final video = await _youtubeExplode.videos.get(videoId);
    final manifest = await _youtubeExplode.videos.streamsClient.getManifest(videoId.value);

    final videoStreams = manifest.muxed
        .map((s) => DownloadableStream(
              url: s.url.toString(),
              quality: '${s.videoResolution.height}p',
              format: s.container.name,
              size: s.size.totalBytes,
            ))
        .toList();

    final audioStreams = manifest.audioOnly
        .map((s) => DownloadableStream(
              url: s.url.toString(),
              quality: '${s.bitrate.kiloBitsPerSecond.round()}kbps',
              format: s.container.name,
              size: s.size.totalBytes,
            ))
        .toList();

    return ExtractedVideoData(
      id: video.id.value,
      title: video.title,
      author: video.author,
      thumbnailUrl: video.thumbnails.highResUrl,
      videoStreams: videoStreams,
      audioStreams: audioStreams,
    );
  }

  @override
  Future<String?> downloadVideoStream(
      ExtractedVideoData videoData, String quality, Function(double) onProgress) async {
    final streamInfo = videoData.videoStreams.firstWhere((s) => s.quality == quality);
    return await _downloadStream(streamInfo, videoData.title, 'mp4', onProgress);
  }

  @override
  Future<String?> downloadAudioStream(
      ExtractedVideoData videoData, Function(double) onProgress) async {
    final streamInfo = videoData.audioStreams.first;
    return await _downloadStream(streamInfo, videoData.title, 'm4a', onProgress);
  }

  Future<String?> _downloadStream(DownloadableStream streamInfo, String title,
      String format, Function(double) onProgress) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(streamInfo.url));
      final response = await client.send(request);

      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/${_sanitizeFileName(title)}.$format';
      final file = File(filePath);
      final fileStream = file.openWrite();

      final totalBytes = response.contentLength ?? streamInfo.size;
      var receivedBytes = 0;

      response.stream.listen(
        (List<int> chunk) {
          fileStream.add(chunk);
          receivedBytes += chunk.length;
          onProgress(receivedBytes / totalBytes);
        },
        onDone: () async {
          await fileStream.flush();
          await fileStream.close();
          client.close();
        },
        onError: (e) async {
          await fileStream.flush();
          await fileStream.close();
          client.close();
        },
        cancelOnError: true,
      );
      return filePath;
    } catch (e) {
      return null;
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[\\/:]'), '_');
  }
}
