import 'package:flutter/material.dart';
import 'package:myapp/features/downloader/services/download_manager.dart';
import 'package:provider/provider.dart';

class DownloadQueueScreen extends StatelessWidget {
  const DownloadQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadManager = Provider.of<DownloadManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Queue'),
      ),
      body: StreamBuilder<List<DownloadTask>>(
        stream: downloadManager.queue,
        initialData: const [],
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final task = snapshot.data![index];
                return DownloadTaskTile(task: task);
              },
            );
          } else {
            return const Center(
              child: Text('No active downloads.'),
            );
          }
        },
      ),
    );
  }
}

class DownloadTaskTile extends StatelessWidget {
  final DownloadTask task;

  const DownloadTaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.title),
      subtitle: ValueListenableBuilder<DownloadStatus>(
        valueListenable: task.status,
        builder: (context, status, child) {
          return Text(status.toString().split('.').last);
        },
      ),
      trailing: SizedBox(
        width: 100,
        child: ValueListenableBuilder<double>(
          valueListenable: task.progress,
          builder: (context, progress, child) {
            return LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
            );
          },
        ),
      ),
    );
  }
}
