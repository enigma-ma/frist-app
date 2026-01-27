import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:myapp/features/downloader/screens/downloader_screen.dart';
import 'package:myapp/models/video.dart';
import 'package:myapp/features/downloader/services/downloader_service.dart';
import 'package:myapp/features/extractor/services/extractor_service.dart';

class PlaylistScreen extends StatefulWidget {
  final yt.Playlist playlist;
  final List<yt.Video> videos;

  const PlaylistScreen({super.key, required this.playlist, required this.videos});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final DownloaderService _downloaderService = DownloaderService();
  final ValueNotifier<int> _downloadedCount = ValueNotifier(0);
  final ValueNotifier<double> _videoProgress = ValueNotifier(0.0);
  bool _isDownloading = false;
  List<String> _videoQualities = [];

 @override
  void initState() {
    super.initState();
    _fetchAvailableQualities();
  }

  Future<void> _fetchAvailableQualities() async {
    if (widget.videos.isNotEmpty) {
      final qualities = await _downloaderService.getAvailableVideoQualities(widget.videos.first.id.value);
      if (mounted) {
        setState(() {
          _videoQualities = qualities;
        });
      }
    }
  }

  Future<void> _downloadAll(String quality) async {
    setState(() {
      _isDownloading = true;
      _downloadedCount.value = 0;
    });

    for (int i = 0; i < widget.videos.length; i++) {
      final video = widget.videos[i];
       _downloadedCount.value = i + 1;
      _videoProgress.value = 0.0;
      await _downloaderService.downloadVideo(video.id.value, video.title, quality, (progress) {
          _videoProgress.value = progress;
      });
    }

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _showQualityPickerAndDownload() {
    if (_videoQualities.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still fetching qualities... Please try again shortly.')),
        );
      }
      if(_videoQualities.isEmpty) _fetchAvailableQualities();
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _videoQualities.length,
          itemBuilder: (context, index) {
            final quality = _videoQualities[index];
            return ListTile(
              title: Text(quality),
              onTap: () {
                Navigator.pop(context);
                _downloadAll(quality);
              },
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.title),
      ),
      body: Column(
        children: [
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _downloadedCount,
                    builder: (context, count, child) {
                      return Text(
                        'Downloading video $count of ${widget.videos.length}',
                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<double>(
                      valueListenable: _videoProgress,
                      builder: (context, progress, child) {
                          return LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          );
                      }
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: _showQualityPickerAndDownload,
                icon: const Icon(Icons.download),
                label: const Text('Download All'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Make button wider
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.videos.length,
              itemBuilder: (context, index) {
                final video = Video.fromYoutubeExplode(widget.videos[index]);
                return ListTile(
                  leading: Image.network(video.thumbnailUrl),
                  title: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(video.author),
                  onTap: () async {
                    if (!_isDownloading) {
                       final scaffoldMessenger = ScaffoldMessenger.of(context);
                       final navigator = Navigator.of(context);

                       scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Fetching video data...')),
                      );

                      try {
                        final extractorFactory = Provider.of<ExtractorFactory>(context, listen: false);
                        final extractor = extractorFactory.getExtractorForUrl(video.id);

                        if (extractor != null) {
                          final videoData = await extractor.getVideoData(video.id);
                          if (mounted) {
                            navigator.push(
                              MaterialPageRoute(
                                builder: (context) => DownloaderScreen(videoData: videoData),
                              ),
                            );
                          }
                        } else {
                           if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text('Could not find a suitable extractor.'), backgroundColor: Colors.red),
                              );
                           }
                        }
                      } catch (e) {
                          if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('Failed to get video data: $e'), backgroundColor: Colors.red),
                              );
                          }
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
