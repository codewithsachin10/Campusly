import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'version_check_service.dart';

final apkInstallerServiceProvider = Provider<ApkInstallerService>((ref) {
  return ApkInstallerService(Supabase.instance.client);
});

class ApkInstallerService {
  final SupabaseClient _supabase;
  final Dio _dio = Dio();

  ApkInstallerService(this._supabase);

  /// Downloads the APK and returns the local file path if successful.
  Future<String?> downloadApk(
    AppReleaseInfo release, {
    required Function(double progress) onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/campusly_update_${release.buildNumber}.apk';
      
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        release.apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      return savePath;
    } catch (e) {
      print('Download failed: $e');
      return null;
    }
  }

  /// Verifies the SHA-256 hash of the downloaded file against the expected hash.
  Future<bool> verifyApkHash(String filePath, String expectedHash) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final stream = file.openRead();
      final hash = await sha256.bind(stream).first;
      final calculatedHash = hash.toString();

      return calculatedHash.toLowerCase() == expectedHash.toLowerCase();
    } catch (e) {
      print('Hash verification failed: $e');
      return false;
    }
  }

  /// Installs the APK using OpenFilex to trigger the native Android installer.
  Future<bool> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      print('Installation failed: $e');
      return false;
    }
  }

  /// Logs analytics events back to Supabase
  Future<void> logAnalytics({
    required int fromBuild,
    required int toBuild,
    required String status,
    String? errorMessage,
  }) async {
    try {
      // If user is not authenticated, we can't log to auth-restricted table
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      await _supabase.from('app_update_analytics').insert({
        'user_id': user.id,
        'from_version_code': fromBuild,
        'to_version_code': toBuild,
        'status': status,
        'error_message': errorMessage,
      });
    } catch (e) {
      print('Analytics logging failed: $e');
    }
  }
}
