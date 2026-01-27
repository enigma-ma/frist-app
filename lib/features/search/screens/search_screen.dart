import 'package:flutter/material.dart';
import 'package:youtube_downloader/features/search/services/youtube_service.dart';
import 'package:youtube_downloader/models/video.dart';
import 'package:youtube_downloader/features/search/widgets/video_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final YoutubeService _youtubeService = YoutubeService();
  final TextEditingController _searchController = TextEditingController();
  List<Video> _videos = [];
  bool _isLoading = false;

  void _search() async {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      final videos = await _youtubeService.searchVideos(_searchController.text);
      setState(() {
        _videos = videos.map((video) => Video.fromYoutubeExplode(video)).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a video',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      return VideoCard(video: _videos[index]);
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
