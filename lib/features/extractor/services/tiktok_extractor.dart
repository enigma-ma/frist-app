import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'extractor_service.dart';

class TikTokExtractor implements Extractor {
  @override
  bool canHandleUrl(String url) {
    return url.contains('tiktok.com');
  }

  @override
  Future<ExtractedVideoData> getVideoData(String url) async {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);
    final responseBody = await response.stream.bytesToString();

    // Crude but effective way to find the video data in the HTML response
    final scriptTag = responseBody.split('<script id="__NEXT_DATA__" type="application/json" crossorigin="anonymous">').last.split('</script>').first;

    final jsonData = jsonDecode(scriptTag);
    final videoData = jsonData['props']['pageProps']['itemInfo']['itemStruct'];

    final videoStreams = [
      DownloadableStream(
        url: videoData['video']['playAddr'],
        quality: '${videoData['video']['height']}p',
        format: 'mp4',
        size: 0, // TikTok doesn't provide size upfront
      )
    ];

    return ExtractedVideoData(
      id: videoData['id'],
      title: videoData['desc'] ?? 'TikTok Video',
      author: videoData['author']['uniqueId'],
      thumbnailUrl: videoData['video']['cover'],
      videoStreams: videoStreams,
      audioStreams: [], // TikTok videos are muxed
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
    // Since TikTok videos are muxed, we can just download the video and the user can extract the audio if needed.
    // Or, we could use a library to extract the audio, but for now we'll just download the video.
    final streamInfo = videoData.videoStreams.first;
    return await _downloadStream(streamInfo, videoData.title, 'mp4', onProgress);
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
