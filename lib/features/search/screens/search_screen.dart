import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/features/downloader/screens/downloader_screen.dart';
import 'package:myapp/features/extractor/services/extractor_service.dart';
import 'package:myapp/features/search/services/youtube_service.dart';
import 'package:myapp/models/video.dart';
import 'package:myapp/features/search/widgets/video_card.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YoutubeService _youtubeService = YoutubeService();
  List<Video> _videos = [];
  bool _isLoading = false;
  String? _pasteError;

  Future<void> _processInput({String? prefilledQuery}) async {
    final query = prefilledQuery ?? _searchController.text.trim();
    if (query.isEmpty) return;

    // Clear previous results and show loading indicator
    setState(() {
      _isLoading = true;
      _videos = [];
      _pasteError = null;
    });

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final extractorFactory =
          Provider.of<ExtractorFactory>(context, listen: false);
      final extractor = extractorFactory.getExtractorForUrl(query);

      if (extractor != null) {
        // It's a URL that one of our extractors can handle
        final videoData = await extractor.getVideoData(query);
        navigator.push(
          MaterialPageRoute(
            builder: (context) => DownloaderScreen(videoData: videoData),
          ),
        );
      } else {
        // It's not a recognized URL, so treat it as a YouTube search query
        final searchResult = await _youtubeService.search(query);
        if (searchResult is List<dynamic>) {
          setState(() {
            _videos = searchResult
                .map((video) => Video.fromYoutubeExplode(video))
                .toList();
          });
        } else {
          _showError('Could not perform search. Please try again.');
        }
      }
    } catch (e) {
      _showError('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text;
    if (text != null && text.isNotEmpty) {
      _searchController.text = text;
      _processInput(prefilledQuery: text);
    } else {
      setState(() {
        _pasteError = "Clipboard is empty!";
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(FontAwesomeIcons.v, color: Colors.blue),
        ),
        title: Text('V-Down',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Navigate to History Screen
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text('A'),
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isNotEmpty
              ? _buildSearchResults()
              : _buildHomeScreen(theme),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return GestureDetector(
          onTap: () => _processInput(prefilledQuery: video.id),
          child: VideoCard(video: video),
        );
      },
    );
  }

  Widget _buildHomeScreen(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, Alex!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What would you like to download today?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
          if (_pasteError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_pasteError!,
                  style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 24),
          _buildSocialShortcuts(theme),
          const SizedBox(height: 32),
          Text(
            'Quick Tips',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildQuickTipCard(
            icon: Icons.paste,
            title: 'One-Click Paste',
            subtitle:
                "Copy any video link and tap 'Paste' to start downloading instantly in high quality.",
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildQuickTipCard(
            icon: Icons.hd,
            title: 'Multiple Formats',
            subtitle:
                "Choose between MP4 for video or MP3 if you only want the audio track from a clip.",
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildQuickTipCard(
            icon: Icons.share,
            title: 'Easy Sharing',
            subtitle:
                "Find your finished downloads in 'My Files' and share them directly with your friends.",
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Paste video URL or search...',
        prefixIcon: const Icon(Icons.link),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ElevatedButton(
            onPressed: _pasteFromClipboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Paste'),
          ),
        ),
      ),
      onSubmitted: (_) => _processInput(),
    );
  }

  Widget _buildSocialShortcuts(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSocialIcon(FontAwesomeIcons.youtube, 'YouTube', Colors.red),
        _buildSocialIcon(
            FontAwesomeIcons.instagram, 'Instagram', Colors.pink),
        _buildSocialIcon(FontAwesomeIcons.tiktok, 'TikTok', Colors.white),
        _buildSocialIcon(
            FontAwesomeIcons.facebook, 'Facebook', Colors.blue),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(16),
          ),
          child: FaIcon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildQuickTipCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
