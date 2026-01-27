import 'package:myapp/database/database_helper.dart';
import 'package:myapp/models/video.dart';
import 'package:sqflite/sqflite.dart';

class HistoryService {
  final dbHelper = DatabaseHelper();

  Future<List<Video>> getDownloadedVideos() async {
    final db = await dbHelper.database;
    final maps = await db.query('videos', orderBy: 'downloadDate DESC');

    return List.generate(maps.length, (i) {
      return Video.fromMap(maps[i]);
    });
  }

  Future<void> saveVideo(Video video) async {
    final db = await dbHelper.database;
    final videoToSave = Video(
      id: video.id,
      title: video.title,
      author: video.author,
      thumbnailUrl: video.thumbnailUrl,
      filePath: video.filePath,
      downloadDate: video.downloadDate ?? DateTime.now(),
    );
    await db.insert(
      'videos',
      videoToSave.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
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
