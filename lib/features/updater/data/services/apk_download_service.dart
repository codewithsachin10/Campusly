import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final apkDownloadServiceProvider = Provider<ApkDownloadService>((ref) {
  return ApkDownloadService(Dio(), Logger());
});

enum DownloadStatus {
  idle,
  downloading,
  downloaded,
  installing,
  failed,
}

class DownloadState {
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String? filePath;
  final String? error;

  const DownloadState({
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.filePath,
    this.error,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    String? filePath,
    String? error,
  }) {
    return DownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
    );
  }
}

class ApkDownloadService {
  final Dio _dio;
  final Logger _logger;
  CancelToken? _cancelToken;

  ApkDownloadService(this._dio, this._logger);

  /// Downloads an APK from [url] and saves it to the app's cache directory.
  /// [onProgress] is called with progress from 0.0 to 1.0.
  Future<String> downloadApk({
    required String url,
    required String version,
    required void Function(double progress) onProgress,
  }) async {
    _cancelToken = CancelToken();

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/campusly_$version.apk';

      // Delete old file if it exists
      final oldFile = File(filePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      _logger.i('Downloading APK from $url to $filePath');

      await _dio.download(
        url,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      _logger.i('APK download complete: $filePath');
      return filePath;
    } catch (e) {
      _logger.e('APK download failed', error: e);
      rethrow;
    }
  }

  /// Opens the downloaded APK file to trigger Android's install prompt.
  Future<void> installApk(String filePath) async {
    try {
      _logger.i('Opening APK for install: $filePath');
      final result = await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
      _logger.i('Install prompt result: ${result.message}');
    } catch (e) {
      _logger.e('Failed to open APK for install', error: e);
      rethrow;
    }
  }

  /// Cancels an in-progress download.
  void cancelDownload() {
    _cancelToken?.cancel('Download cancelled by user');
  }
}
