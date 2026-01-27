import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HistoryService {
  Future<List<File>> getDownloadedFiles() async {
    final directory = await getExternalStorageDirectory();
    final files = directory!.listSync();
    return files.where((file) => file.path.endsWith('.mp3') || file.path.endsWith('.mp4')).map((file) => File(file.path)).toList();
  }
}
