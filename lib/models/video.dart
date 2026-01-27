class Video {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;

  Video({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
  });

  factory Video.fromYoutubeExplode(dynamic video) {
    return Video(
      id: video.id.value,
      title: video.title,
      author: video.author,
      thumbnailUrl: video.thumbnails.mediumResUrl,
    );
  }
}
