
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloaderService {
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  Future<bool> requestPermission() async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    return status.isGranted;
  }

  Future<List<String>> getAvailableVideoQualities(String videoId) async {
    try {
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(videoId);
      final qualities = <String>{};
      for (var stream in manifest.muxed) {
        qualities.add('${stream.videoResolution.height}p');
      }
      final sortedQualities = qualities.toList();
      sortedQualities.sort((a, b) {
        final aRes = int.tryParse(a.replaceAll('p', '')) ?? 0;
        final bRes = int.tryParse(b.replaceAll('p', '')) ?? 0;
        return bRes.compareTo(aRes);
      });
      return sortedQualities;
    } catch (e) {
      return [];
    }
  }

  Future<String?> downloadAudio(String videoId, String videoTitle, Function(double) onProgress) async {
    if (!await requestPermission()) return null;

    try {
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/${_sanitizeFileName(videoTitle)}.m4a';
      final file = File(filePath);
      final fileStream = file.openWrite();

      final totalBytes = streamInfo.size.totalBytes;
      var receivedBytes = 0;

      final stream = _youtubeExplode.videos.streamsClient.get(streamInfo);
      await for (var data in stream) {
        receivedBytes += data.length;
        fileStream.add(data);
        onProgress(receivedBytes / totalBytes);
      }

      await fileStream.flush();
      await fileStream.close();
      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<String?> downloadVideo(String videoId, String videoTitle, String quality, Function(double) onProgress) async {
    if (!await requestPermission()) return null;

    try {
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.muxed.firstWhere((s) => '${s.videoResolution.height}p' == quality);

      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/${_sanitizeFileName(videoTitle)}.mp4';
      final file = File(filePath);
      final fileStream = file.openWrite();

      final totalBytes = streamInfo.size.totalBytes;
      var receivedBytes = 0;

      final stream = _youtubeExplode.videos.streamsClient.get(streamInfo);
      await for (var data in stream) {
        receivedBytes += data.length;
        fileStream.add(data);
        onProgress(receivedBytes / totalBytes);
      }

      await fileStream.flush();
      await fileStream.close();
      return filePath;
    } catch (e) {
      return null;
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[\\/:]'), '_');
  }
}
