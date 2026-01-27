import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/models/video.dart';
import 'package:myapp/services/history_service.dart';
import 'package:path_provider/path_provider.dart';

class DownloadTask {
  final String id;
  final String url;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String format;
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<DownloadStatus> status = ValueNotifier(DownloadStatus.pending);

  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.format,
  });
}

enum DownloadStatus { pending, downloading, completed, failed, paused }

class DownloadManager with ChangeNotifier {
  final HistoryService _historyService = HistoryService();
  final List<DownloadTask> _queue = [];
  final List<DownloadTask> _completed = [];
  final List<DownloadTask> _failed = [];
  final int _maxConcurrentDownloads = 3;
  int _currentDownloads = 0;

  List<DownloadTask> get queue => _queue;
  List<DownloadTask> get completed => _completed;
  List<DownloadTask> get failed => _failed;

  DownloadManager() {
   // Periodically notify listeners to update UI for progress
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      notifyListeners();
    });
  }

  void addToQueue(DownloadTask task) {
    _queue.add(task);
    notifyListeners();
    _processQueue();
  }

  void _processQueue() {
    if (_currentDownloads >= _maxConcurrentDownloads || _queue.isEmpty) {
      return;
    }

    final task = _queue.firstWhere((t) => t.status.value == DownloadStatus.pending, orElse: () => _queue.first);
    _currentDownloads++;
    task.status.value = DownloadStatus.downloading;
    notifyListeners();

    _download(task).whenComplete(() {
      _currentDownloads--;
      _queue.remove(task);
       if (task.status.value == DownloadStatus.completed) {
        _completed.insert(0, task);
      } else if (task.status.value == DownloadStatus.failed) {
        _failed.insert(0, task);
      }
      notifyListeners();
      _processQueue();
    });
  }

  Future<void> _download(DownloadTask task) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(task.url));
      final response = await client.send(request);

      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/${_sanitizeFileName(task.title)}.${task.format}';
      final file = File(filePath);
      final fileStream = file.openWrite();

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      await response.stream.listen(
        (List<int> chunk) {
           if (task.status.value != DownloadStatus.downloading) return; // Handle pause/cancel
          fileStream.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            task.progress.value = receivedBytes / totalBytes;
          }
        },
        onDone: () async {
          await fileStream.flush();
          await fileStream.close();
          task.status.value = DownloadStatus.completed;
          final videoToSave = Video(
            id: task.id,
            title: task.title,
            author: task.author,
            thumbnailUrl: task.thumbnailUrl,
            filePath: filePath,
          );
          await _historyService.saveVideo(videoToSave);
          client.close();
        },
        onError: (e) {
          task.status.value = DownloadStatus.failed;
          client.close();
        },
        cancelOnError: true
      ).asFuture();
    } catch (e) {
      task.status.value = DownloadStatus.failed;
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  void pauseDownload(DownloadTask task) {
    if (task.status.value == DownloadStatus.downloading) {
        task.status.value = DownloadStatus.paused;
        notifyListeners();
    }
  }

  void resumeDownload(DownloadTask task) {
     if (task.status.value == DownloadStatus.paused) {
        task.status.value = DownloadStatus.downloading;
        notifyListeners();
        // The download stream listener will resume
    }
  }

  void cancelDownload(DownloadTask task) {
    _queue.remove(task);
    task.status.value = DownloadStatus.failed; // Or a new 'cancelled' status
    notifyListeners();
  }
}
