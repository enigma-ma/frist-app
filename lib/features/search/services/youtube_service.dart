import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'search_exceptions.dart';

enum SearchInputType {
  query,
  video,
  playlist,
}

class YoutubeService {
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  SearchInputType getSearchInputType(String input) {
    if (input.contains('list=')) {
      return SearchInputType.playlist;
    }
    if (input.contains('youtube.com/watch?v=') || input.contains('youtu.be/')) {
      return SearchInputType.video;
    }
    return SearchInputType.query;
  }

  Future<dynamic> search(String input) async {
    final inputType = getSearchInputType(input);
    try {
      switch (inputType) {
        case SearchInputType.query:
           final searchResult = await _youtubeExplode.search.search(input);
           return searchResult.toList();
        case SearchInputType.video:
          return await _youtubeExplode.videos.get(VideoId(input));
        case SearchInputType.playlist:
          final playlist = await _youtubeExplode.playlists.get(PlaylistId(input));
          final videos = await _youtubeExplode.playlists.getVideos(playlist.id).toList();
          return {'playlist': playlist, 'videos': videos};
      }
    } catch (e) {
      if (kIsWeb && e.toString().contains('XMLHttpRequest')) {
        throw SearchException(
            'This functionality is not available on the web due to browser restrictions.');
      } else {
        throw SearchException('An unexpected error occurred.');
      }
    }
  }

  Future<StreamManifest> getStreamManifest(String videoId) async {
    return await _youtubeExplode.videos.streamsClient.getManifest(videoId);
  }
}
