import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/features/downloader/services/download_manager.dart';
import 'package:provider/provider.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadManager = Provider.of<DownloadManager>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Downloads'),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
          ],
          bottom: TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              _buildTab('Downloading', downloadManager.queue.length),
              _buildTab('Completed', downloadManager.completed.length),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DownloadingTab(),
            CompletedTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () { /* TODO: Add new download */ },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTab(String text, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text),
          if (count > 0)
            const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(count.toString(), style: TextStyle(color: Colors.blue, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class DownloadingTab extends StatelessWidget {
  const DownloadingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadManager>(
      builder: (context, downloadManager, child) {
        final activeTasks = downloadManager.queue;
        if (activeTasks.isEmpty) {
            return const Center(child: Text('No active downloads.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeTasks.length,
          itemBuilder: (context, index) {
            final task = activeTasks[index];
            return ActiveDownloadCard(task: task);
          },
        );
      },
    );
  }
}

class CompletedTab extends StatelessWidget {
  const CompletedTab({super.key});

  @override
  Widget build(BuildContext context) {
     return Consumer<DownloadManager>(
      builder: (context, downloadManager, child) {
        final completedTasks = downloadManager.completed;

        if (completedTasks.isEmpty) {
            return const Center(child: Text('No completed downloads yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedTasks.length,
          itemBuilder: (context, index) {
            final task = completedTasks[index];
            return CompletedDownloadCard(task: task);
          },
        );
      },
    );
  }
}

class ActiveDownloadCard extends StatelessWidget {
  final DownloadTask task;

  const ActiveDownloadCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadManager = Provider.of<DownloadManager>(context, listen: false);
    final isPaused = task.status.value == DownloadStatus.paused;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(task.thumbnailUrl, width: 100, height: 60, fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800], width: 100, height: 60, child: Icon(Icons.image_not_supported)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(isPaused ? FontAwesomeIcons.pause : FontAwesomeIcons.download, size: 12, color: Colors.grey),
                        const SizedBox(width: 6),
                        if (!isPaused)
                          Text('2.8 MB/s', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)), // Placeholder
                        if (isPaused)
                          Text('Paused', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        const SizedBox(width: 4),
                        const Text('•', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 4),
                        Text('45.2 MB of 120 MB', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)), // Placeholder
                      ],
                    )
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: () {
                   if (isPaused) {
                      downloadManager.resumeDownload(task);
                   } else {
                      downloadManager.pauseDownload(task);
                   }
                }
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => downloadManager.cancelDownload(task)),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<double>(
            valueListenable: task.progress,
            builder: (context, progress, child) {
              return Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(progress * 100).toInt()}% complete', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Text('12s remaining', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)), // Placeholder
                ],
              );
            },
          )
        ],
      ),
    );
  }
}

class CompletedDownloadCard extends StatelessWidget {
  final DownloadTask task;

  const CompletedDownloadCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
               ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(task.thumbnailUrl, width: 120, height: 70, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800], width: 120, height: 70, child: Icon(Icons.image_not_supported)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                     Row(
                       children: [
                         Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(4)), child: Text(task.format.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                         SizedBox(width: 8),
                         Text('24.5 MB', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)), // Placeholder
                         SizedBox(width: 4),
                         Text('•', style: TextStyle(color: Colors.grey)),
                         SizedBox(width: 4),
                         Text('2h ago', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)), // Placeholder
                       ],
                     )
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(context, icon: Icons.play_arrow, label: 'Play', onTap: () {}),
              _buildActionButton(context, icon: Icons.share, label: 'Share', onTap: () {}),
              _buildActionButton(context, icon: Icons.save_alt, label: 'Save', onTap: () {}),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[300], size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey[300])),
          ],
        ),
      ),
    );
  }
}
