import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  Future<List<Video>> searchVideos(String query) async {
    try {
      final searchResult = await _youtubeExplode.search.getVideos(query);
      return searchResult.toList();
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }

  Future<StreamManifest> getStreamManifest(String videoId) async {
    return await _youtubeExplode.videos.streamsClient.getManifest(videoId);
  }
}
