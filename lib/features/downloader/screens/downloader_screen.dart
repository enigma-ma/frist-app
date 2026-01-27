import 'package:flutter/material.dart';
import 'package:myapp/models/video.dart';
import 'package:myapp/features/downloader/services/downloader_service.dart';
import 'package:myapp/services/history_service.dart';

class DownloaderScreen extends StatefulWidget {
  final Video video;

  const DownloaderScreen({super.key, required this.video});

  @override
  State<DownloaderScreen> createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends State<DownloaderScreen> {
  final DownloaderService _downloaderService = DownloaderService();
  final HistoryService _historyService = HistoryService();
  final ValueNotifier<double> _downloadProgress = ValueNotifier(0.0);
  bool _isDownloading = false;

  Future<void> _downloadAudio() async {
    setState(() {
      _isDownloading = true;
    });
    final filePath = await _downloaderService.downloadAudio(widget.video.id, widget.video.title);
    if (filePath != null) {
      final videoToSave = Video(
        id: widget.video.id,
        title: widget.video.title,
        author: widget.video.author,
        thumbnailUrl: widget.video.thumbnailUrl,
        filePath: filePath,
      );
      await _historyService.saveVideo(videoToSave);
    }
    setState(() {
      _isDownloading = false;
    });
  }

  Future<void> _downloadVideo() async {
    setState(() {
      _isDownloading = true;
    });
    final filePath = await _downloaderService.downloadVideo(widget.video.id, widget.video.title);
    if (filePath != null) {
      final videoToSave = Video(
        id: widget.video.id,
        title: widget.video.title,
        author: widget.video.author,
        thumbnailUrl: widget.video.thumbnailUrl,
        filePath: filePath,
      );
      await _historyService.saveVideo(videoToSave);
    }
    setState(() {
      _isDownloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              widget.video.thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.video.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                widget.video.author,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isDownloading
                ? ValueListenableBuilder<double>(
                    valueListenable: _downloadProgress,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                      );
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _downloadAudio,
                        icon: const Icon(Icons.audiotrack),
                        label: const Text('Download Audio'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _downloadVideo,
                        icon: const Icon(Icons.videocam),
                        label: const Text('Download Video'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
