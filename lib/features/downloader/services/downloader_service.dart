import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloaderService {
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  Future<bool> requestPermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> downloadAudio(String videoId, String videoTitle) async {
    if (await requestPermission()) {
      try {
        final streamManifest = await _youtubeExplode.videos.streamsClient.getManifest(videoId);
        final audioStream = streamManifest.audioOnly.withHighestBitrate();
        final directory = await getExternalStorageDirectory();
        final filePath = '${directory!.path}/$videoTitle.mp3';
        final file = File(filePath);
        final fileStream = file.openWrite();

        await _youtubeExplode.videos.streamsClient.get(audioStream).pipe(fileStream);

        await fileStream.flush();
        await fileStream.close();
      } catch (e) {
        print('Error downloading audio: $e');
      }
    }
  }

  Future<void> downloadVideo(String videoId, String videoTitle) async {
    if (await requestPermission()) {
      try {
        final streamManifest = await _youtubeExplode.videos.streamsClient.getManifest(videoId);
        final videoStream = streamManifest.muxed.withHighestBitrate();
        final directory = await getExternalStorageDirectory();
        final filePath = '${directory!.path}/$videoTitle.mp4';
        final file = File(filePath);
        final fileStream = file.openWrite();

        await _youtubeExplode.videos.streamsClient.get(videoStream).pipe(fileStream);

        await fileStream.flush();
        await fileStream.close();
      } catch (e) {
        print('Error downloading video: $e');
      }
    }
  }
}
