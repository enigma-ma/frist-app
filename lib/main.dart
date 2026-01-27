import 'package:flutter/material.dart';
import 'package:myapp/features/downloader/services/download_manager.dart';
import 'package:provider/provider.dart';

import 'package:myapp/app/theme/app_theme.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/features/extractor/services/extractor_service.dart';
import 'package:myapp/features/extractor/services/youtube_extractor.dart';
import 'package:myapp/features/extractor/services/tiktok_extractor.dart';

import 'package:myapp/features/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final extractors = [
    YouTubeExtractor(),
    TikTokExtractor(),
  ];

  final extractorFactory = ExtractorFactory(extractors);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<ExtractorFactory>.value(value: extractorFactory),
        ChangeNotifierProvider(create: (_) => DownloadManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'All-in-One Downloader',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Force dark theme
          home: const MainScreen(),
        );
      },
    );
  }
}
