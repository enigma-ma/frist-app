
# YouTube Downloader Application Blueprint

## Overview

This document outlines the design and features of a YouTube Downloader application built with Flutter. The app allows users to search for YouTube videos, download them in various formats, manage their download history, and customize settings.

## Features

* **Search:** Users can search for YouTube videos by entering a query. The app will display a list of search results with thumbnails, titles, and channel information.
* **Downloader:** Users can select a video from the search results and choose to download it as an audio or video file. The app will display the download progress and status.
* **History:** The app will maintain a history of downloaded videos, allowing users to easily access and manage their downloaded content.
* **Settings:** Users can customize the app's settings, such as the preferred download quality and theme (light/dark mode).

## Architecture

The app follows a feature-first architecture, with each feature (search, downloader, history, settings) having its own dedicated directory containing the necessary widgets, screens, and services. The app uses the `provider` package for state management, specifically for managing the theme.

## Final Implementation

### Step 1: Project Setup and Initial UI

* **Create Project Structure:** Set up the basic directory structure for the project, including folders for each feature, as well as for models, providers, and themes.
* **Initialize Firebase:** Initialize Firebase in the `main.dart` file.
* **Implement Basic UI:** Create the main screen of the application with a `BottomNavigationBar` to switch between the different features. Create placeholder screens for each feature.
* **Set up Theme:** Create a `ThemeProvider` to manage the app's theme and define light and dark themes in an `app_theme.dart` file.

### Step 2: Search and Downloader Implementation

*   **Add Dependencies:** Add `youtube_explode_dart`, `permission_handler`, and `path_provider` to `pubspec.yaml`.
*   **Create YoutubeService:** Implement a `YoutubeService` to fetch video data from YouTube.
*   **Create Video Model:** Create a `Video` model to represent video data.
*   **Implement Search UI:** Update the `SearchScreen` to use the `YoutubeService` to search for videos and display the results in a `ListView`.
*   **Create DownloaderService:** Implement a `DownloaderService` to handle the logic for downloading audio and video streams.
*   **Implement Downloader UI:** Update the `DownloaderScreen` to allow users to download the selected video as an audio or video file. Display a progress indicator during the download.

### Step 3: History and Settings Implementation

*   **Create HistoryService:** Implement a `HistoryService` to get the list of downloaded files.
*   **Implement History UI:** Update the `HistoryScreen` to display the list of downloaded files and allow users to delete them.
*   **Implement Settings UI:** Update the `SettingsScreen` to include a `Switch` to toggle between light and dark themes.
