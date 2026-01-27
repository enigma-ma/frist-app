import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/features/downloader/services/download_manager.dart';
import 'package:myapp/features/extractor/services/extractor_service.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class DownloaderScreen extends StatefulWidget {
  final ExtractedVideoData videoData;

  const DownloaderScreen({super.key, required this.videoData});

  @override
  State<DownloaderScreen> createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends State<DownloaderScreen> {
  late VideoPlayerController _controller;
  DownloadableStream? _selectedStream;

  @override
  void initState() {
    super.initState();
    // Find a playable video stream for the preview
    final playableStream = widget.videoData.videoStreams.firstWhere(
      (s) => s.url.isNotEmpty,
      orElse: () => widget.videoData.audioStreams.first, // Fallback to audio if no video
    );

    _controller = VideoPlayerController.networkUrl(Uri.parse(playableStream.url))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        setState(() {});
      });

    // Pre-select the highest quality video stream
    if (widget.videoData.videoStreams.isNotEmpty) {
      _selectedStream = widget.videoData.videoStreams.reduce(
          (a, b) => a.size > b.size ? a : b); // Simple quality heuristic
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startDownload() {
    if (_selectedStream == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a download option first.')),
      );
      return;
    }

    final downloadManager = Provider.of<DownloadManager>(context, listen: false);
    final task = DownloadTask(
      id: widget.videoData.id,
      url: _selectedStream!.url,
      title: widget.videoData.title,
      author: widget.videoData.author,
      thumbnailUrl: widget.videoData.thumbnailUrl,
      format: _selectedStream!.format,
    );
    downloadManager.addToQueue(task);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${widget.videoData.title}" to download queue.'),
        backgroundColor: Colors.green,
      ),
    );
    // Optionally, navigate to the downloads screen
    // Navigator.pop(context); // Or navigate to downloads tab
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSizeMB = _selectedStream != null
        ? (_selectedStream!.size / 1048576).toStringAsFixed(2)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Options'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement sharing functionality
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoPlayer(theme),
            const SizedBox(height: 24),
            _buildVideoDetails(theme),
            const SizedBox(height: 24),
            _buildSectionHeader(theme, icon: Icons.videocam, title: 'Video Options'),
            ..._buildStreamOptions(widget.videoData.videoStreams, isVideo: true),
            const SizedBox(height: 24),
             _buildSectionHeader(theme, icon: Icons.music_note, title: 'Music Options'),
            ..._buildStreamOptions(widget.videoData.audioStreams, isVideo: false),
          ],
        ),
      ),
      bottomNavigationBar: _buildDownloadButton(selectedSizeMB, theme),
    );
  }

  Widget _buildVideoPlayer(ThemeData theme) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _controller.value.isInitialized
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    IconButton(
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 60,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                    ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildVideoDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.videoData.title,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              widget.videoData.author,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
             Text('1.2M views', style: TextStyle(color: Colors.grey[400])), // Placeholder
             const SizedBox(width: 8),
             const Text('•', style: TextStyle(color: Colors.grey)),
             const SizedBox(width: 8),
             Text('2 days ago', style: TextStyle(color: Colors.grey[400])), // Placeholder
             const Spacer(),
             Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6)
                ),
                child: const Text('YOUTUBE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
             )
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, {required IconData icon, required String title}) {
     return Padding(
       padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
       child: Row(
         children: [
           Icon(icon, color: theme.iconTheme.color, size: 20),
           const SizedBox(width: 8),
           Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
         ],
       ),
     );
  }

  List<Widget> _buildStreamOptions(List<DownloadableStream> streams, {required bool isVideo}) {
    if (streams.isEmpty) {
      return [const Padding(padding: EdgeInsets.all(16), child: Text('No options available.'))];
    }
    return streams.map((stream) {
       final isSelected = _selectedStream == stream;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Material(
           color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[850],
           borderRadius: BorderRadius.circular(12),
           child: InkWell(
              onTap: () => setState(() => _selectedStream = stream),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                    border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                 ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVideo ? stream.quality : '${stream.format.toUpperCase()} - ${stream.quality}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        if (stream.quality == '1080p') // Example badge
                            const Text('PREMIUM QUALITY', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                        if (stream.quality == '720p') // Example badge
                             const Text('RECOMMENDED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                         if (!isVideo)
                             const Text('Audio Only', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Text(
                        '${(stream.size / 1048576).toStringAsFixed(2)} MB',
                        style: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
           ),
        ),
      );
    }).toList();
  }


  Widget _buildDownloadButton(String size, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.download),
        label: Text('Download Now ($size MB)'),
        onPressed: _startDownload,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

}
