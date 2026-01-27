import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp/models/video.dart';
import 'package:myapp/services/history_service.dart';

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
    if (video.filePath != null) {
      final file = File(video.filePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _historyService.deleteVideo(video.id);
    _loadVideos();
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
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final video = snapshot.data![index];
                return ListTile(
                  leading: Image.network(video.thumbnailUrl, width: 100, fit: BoxFit.cover),
                  title: Text(video.title),
                  subtitle: Text(video.author),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteVideo(video),
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
