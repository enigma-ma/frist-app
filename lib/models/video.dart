class Video {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String? filePath;

  Video({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    this.filePath,
  });

  factory Video.fromYoutubeExplode(dynamic video) {
    return Video(
      id: video.id.value,
      title: video.title,
      author: video.author,
      thumbnailUrl: video.thumbnails.mediumResUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'thumbnailUrl': thumbnailUrl,
      'filePath': filePath,
    };
  }

  factory Video.fromMap(Map<String, dynamic> map) {
    return Video(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      thumbnailUrl: map['thumbnailUrl'],
      filePath: map['filePath'],
    );
  }
}
