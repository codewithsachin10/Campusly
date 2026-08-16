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
  final bool isUpdateAvailable;
  final bool isMandatory;
  final bool downloadInProgress;
  final double downloadProgress;

  UpdateState({
    this.isLoading = false,
    this.error,
    this.latestRelease,
    this.currentVersion,
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
      
      final currentSemanticVersion = SemanticVersion.parse(currentVersionStr);
      
      final latestRelease = await updateService.getLatestRelease();
      
      if (latestRelease != null) {
        final latestSemanticVersion = SemanticVersion.parse(latestRelease.version);
        final isUpdateAvailable = latestSemanticVersion > currentSemanticVersion;
        
        final minimumSemanticVersion = SemanticVersion.parse(latestRelease.minimumSupportedVersion);
        final isMandatory = currentSemanticVersion < minimumSemanticVersion || latestRelease.priority == ReleasePriority.critical;

        state = state.copyWith(
          isLoading: false,
          latestRelease: latestRelease,
          currentVersion: currentVersionStr,
          isUpdateAvailable: isUpdateAvailable,
          isMandatory: isMandatory,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          currentVersion: currentVersionStr,
          isUpdateAvailable: false,
        );
      }
    } catch (e, _) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
          .eq('status', 'PUBLISHED')
          .eq('is_published', true)
          .eq('channel', 'STABLE')
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
          .eq('status', 'PUBLISHED')
          .eq('is_published', true)
          .order('published_at', ascending: false)
          .limit(10);

      return (response as List).map((e) => AppRelease.fromJson(e)).toList();
    } catch (e, st) {
      _logger.e('Failed to fetch previous releases', error: e, stackTrace: st);
      return [];
    }
  }
}
