import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/video.dart';
import 'package:myapp/services/history_service.dart';
import 'package:open_file/open_file.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  late Future<List<Video>> _downloadedVideos;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void _loadVideos() {
    setState(() {
      _downloadedVideos = _historyService.getDownloadedVideos();
    });
  }

  Future<void> _deleteVideo(Video video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (video.filePath != null) {
        final file = File(video.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _historyService.deleteVideo(video.id);
      _loadVideos();
    }
  }

  Future<void> _openVideo(Video video) async {
    if (video.filePath != null) {
      final result = await OpenFile.open(video.filePath);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: ${result.message}')),
          );
        }
      }
    }
  }

  Future<String> _getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final bytes = await file.length();
      return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: FutureBuilder<List<Video>>(
        future: _downloadedVideos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading downloaded videos'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No downloaded videos yet'));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final video = snapshot.data![index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Image.network(video.thumbnailUrl, width: 100, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.image, size: 50)),
                        title: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video.author),
                            const SizedBox(height: 4),
                            FutureBuilder<String>(
                              future: _getFileSize(video.filePath!),
                              builder: (context, snapshot) {
                                return Text(
                                  '${snapshot.data ?? '... MB'} - ${DateFormat.yMMMd().format(video.downloadDate!)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _openVideo(video),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Open'),
                          ),
                          TextButton.icon(
                            onPressed: () => _deleteVideo(video),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
