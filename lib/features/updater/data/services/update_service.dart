import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';

import 'package:campusly/features/updater/data/models/app_release.dart';
import 'package:campusly/core/utils/semantic_version.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(Supabase.instance.client, Logger());
});

final updateNotifierProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);

class UpdateState {
  final bool isLoading;
  final String? error;
  final AppRelease? latestRelease;
  final String? currentVersion;
  final int? currentBuildNumber;
  final DateTime? lastCheckedAt;
  final bool isUpdateAvailable;
  final bool isMandatory;
  final bool downloadInProgress;
  final double downloadProgress;

  UpdateState({
    this.isLoading = false,
    this.error,
    this.latestRelease,
    this.currentVersion,
    this.currentBuildNumber,
    this.lastCheckedAt,
    this.isUpdateAvailable = false,
    this.isMandatory = false,
    this.downloadInProgress = false,
    this.downloadProgress = 0.0,
  });

  UpdateState copyWith({
    bool? isLoading,
    String? error,
    AppRelease? latestRelease,
    String? currentVersion,
    int? currentBuildNumber,
    DateTime? lastCheckedAt,
    bool? isUpdateAvailable,
    bool? isMandatory,
    bool? downloadInProgress,
    double? downloadProgress,
  }) {
    return UpdateState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      latestRelease: latestRelease ?? this.latestRelease,
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      isUpdateAvailable: isUpdateAvailable ?? this.isUpdateAvailable,
      isMandatory: isMandatory ?? this.isMandatory,
      downloadInProgress: downloadInProgress ?? this.downloadInProgress,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() {
    return UpdateState();
  }

  Future<void> checkForUpdates() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final updateService = ref.read(updateServiceProvider);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;
      final currentBuildStr = packageInfo.buildNumber;
      final currentBuildNum = int.tryParse(currentBuildStr) ?? 0;
      
      final currentSemanticVersion = SemanticVersion.parse(currentVersionStr);
      
      final latestRelease = await updateService.getLatestRelease();
      
      if (latestRelease != null) {
        final latestSemanticVersion = SemanticVersion.parse(latestRelease.version);
        
        bool isUpdateAvailable = false;
        if (latestSemanticVersion > currentSemanticVersion) {
          isUpdateAvailable = true;
        } else if (latestSemanticVersion == currentSemanticVersion) {
          if (latestRelease.buildNumber > currentBuildNum) {
            isUpdateAvailable = true;
          }
        }

        // Safety check: if current version or build is >= latest, update is not available
        if (currentSemanticVersion > latestSemanticVersion ||
            (currentSemanticVersion == latestSemanticVersion && currentBuildNum >= latestRelease.buildNumber)) {
          isUpdateAvailable = false;
        }
        
        final minimumSemanticVersion = SemanticVersion.parse(latestRelease.minimumSupportedVersion);
        final isMandatory = (currentSemanticVersion < minimumSemanticVersion) ||
            (isUpdateAvailable && latestRelease.priority == ReleasePriority.critical);

        state = state.copyWith(
          isLoading: false,
          latestRelease: latestRelease,
          currentVersion: currentVersionStr,
          currentBuildNumber: currentBuildNum,
          isUpdateAvailable: isUpdateAvailable,
          isMandatory: isMandatory,
          lastCheckedAt: DateTime.now(),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          currentVersion: currentVersionStr,
          currentBuildNumber: currentBuildNum,
          isUpdateAvailable: false,
          lastCheckedAt: DateTime.now(),
        );
      }
    } catch (e, _) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastCheckedAt: DateTime.now(),
      );
    }
  }

  Future<List<AppRelease>> getPreviousReleases() async {
    final updateService = ref.read(updateServiceProvider);
    return updateService.getPreviousReleases();
  }
}

class UpdateService {
  final SupabaseClient _supabase;
  final Logger _logger;

  UpdateService(this._supabase, this._logger);

  Future<AppRelease?> getLatestRelease() async {
    try {
      final response = await _supabase
          .from('app_releases')
          .select('*, release_notes(*)')
          .or('status.eq.PUBLISHED,is_published.eq.true')
          .order('published_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return AppRelease.fromJson(response);
      }
      return null;
    } catch (e, st) {
      _logger.e('Failed to fetch latest release', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<AppRelease>> getPreviousReleases() async {
    try {
      final response = await _supabase
          .from('app_releases')
          .select('*, release_notes(*)')
          .or('status.eq.PUBLISHED,is_published.eq.true')
          .order('published_at', ascending: false)
          .limit(10);

      return (response as List).map((e) => AppRelease.fromJson(e)).toList();
    } catch (e, st) {
      _logger.e('Failed to fetch previous releases', error: e, stackTrace: st);
      return [];
    }
  }
}
