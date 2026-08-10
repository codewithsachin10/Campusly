import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final versionCheckServiceProvider = Provider<VersionCheckService>((ref) {
  return VersionCheckService(Supabase.instance.client);
});

enum UpdateType {
  OPTIONAL,
  RECOMMENDED,
  MANDATORY,
}

class AppReleaseInfo {
  final String id;
  final String version;
  final int buildNumber;
  final String releaseTitle;
  final String releaseNotes;
  final UpdateType updateType;
  final int minSupportedBuild;
  final String apkUrl;
  final int apkSize;
  final String apkSha256;

  AppReleaseInfo({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.updateType,
    required this.minSupportedBuild,
    required this.apkUrl,
    required this.apkSize,
    required this.apkSha256,
  });

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    UpdateType type;
    switch (json['update_type']) {
      case 'MANDATORY':
        type = UpdateType.MANDATORY;
        break;
      case 'OPTIONAL':
        type = UpdateType.OPTIONAL;
        break;
      case 'RECOMMENDED':
      default:
        type = UpdateType.RECOMMENDED;
        break;
    }

    return AppReleaseInfo(
      id: json['id'],
      version: json['version'],
      buildNumber: json['build_number'],
      releaseTitle: json['release_title'] ?? 'New Update Available',
      releaseNotes: json['release_notes'] ?? '',
      updateType: type,
      minSupportedBuild: json['minimum_supported_build'] ?? 1,
      apkUrl: json['apk_url'],
      apkSize: json['apk_size'] ?? 0,
      apkSha256: json['apk_sha256'] ?? '',
    );
  }
}

class VersionCheckResult {
  final bool updateAvailable;
  final AppReleaseInfo? releaseInfo;

  VersionCheckResult({
    required this.updateAvailable,
    this.releaseInfo,
  });
}

class VersionCheckService {
  final SupabaseClient _supabase;

  VersionCheckService(this._supabase);

  Future<VersionCheckResult> checkForUpdates() async {
    // Return early if not Android, as this spec is currently Android-focused
    if (!Platform.isAndroid) {
       return VersionCheckResult(updateAvailable: false);
    }

    try {
      // 1. Get current installed version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      // 2. Fetch latest PUBLISHED release from Supabase
      // Using .maybeSingle() since we limit to 1
      final response = await _supabase
          .from('app_releases')
          .select()
          .eq('status', 'PUBLISHED')
          .eq('platform', 'android')
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return VersionCheckResult(updateAvailable: false);
      }

      final latestRelease = AppReleaseInfo.fromJson(response);

      // 3. Compare versions
      if (currentBuildNumber < latestRelease.buildNumber) {
        // If the current build is below the minimum supported build, dynamically upgrade the update type to MANDATORY
        final effectiveReleaseInfo = currentBuildNumber < latestRelease.minSupportedBuild
            ? AppReleaseInfo(
                id: latestRelease.id,
                version: latestRelease.version,
                buildNumber: latestRelease.buildNumber,
                releaseTitle: latestRelease.releaseTitle,
                releaseNotes: latestRelease.releaseNotes,
                updateType: UpdateType.MANDATORY,
                minSupportedBuild: latestRelease.minSupportedBuild,
                apkUrl: latestRelease.apkUrl,
                apkSize: latestRelease.apkSize,
                apkSha256: latestRelease.apkSha256,
              )
            : latestRelease;

        return VersionCheckResult(
          updateAvailable: true,
          releaseInfo: effectiveReleaseInfo,
        );
      }

      return VersionCheckResult(updateAvailable: false);
    } catch (e) {
      print('Error checking for updates: $e');
      // On network failure or error, fail gracefully allowing user to enter app
      return VersionCheckResult(updateAvailable: false);
    }
  }
}
