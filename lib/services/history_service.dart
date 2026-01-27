import 'package:myapp/database/database_helper.dart';
import 'package:myapp/models/video.dart';

class HistoryService {
  final dbHelper = DatabaseHelper();

  Future<List<Video>> getDownloadedVideos() async {
    final db = await dbHelper.database;
    final maps = await db.query('videos');

    return List.generate(maps.length, (i) {
      return Video.fromMap(maps[i]);
    });
  }

  Future<void> saveVideo(Video video) async {
    final db = await dbHelper.database;
    await db.insert(
      'videos',
      video.toMap(),
    );
  }

  Future<void> deleteVideo(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'videos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
