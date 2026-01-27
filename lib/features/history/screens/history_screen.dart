import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_downloader/features/history/services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  late Future<List<File>> _downloadedFiles;

  @override
  void initState() {
    super.initState();
    _downloadedFiles = _historyService.getDownloadedFiles();
  }

  void _deleteFile(File file) async {
    await file.delete();
    setState(() {
      _downloadedFiles = _historyService.getDownloadedFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: FutureBuilder<List<File>>(
        future: _downloadedFiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading downloaded files'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No downloaded files yet'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final file = snapshot.data![index];
                return ListTile(
                  title: Text(file.path.split('/').last),
                  leading: const Icon(Icons.video_file),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteFile(file),
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
