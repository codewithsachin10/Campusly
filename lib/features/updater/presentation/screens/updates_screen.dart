import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:campusly/core/theme/app_colors.dart';
import 'package:campusly/core/theme/app_typography.dart';
import 'package:campusly/features/updater/data/models/app_release.dart';
import 'package:campusly/features/updater/data/services/update_service.dart';
import 'package:campusly/features/updater/data/services/apk_download_service.dart';

class UpdatesScreen extends ConsumerStatefulWidget {
  const UpdatesScreen({super.key});

  @override
  ConsumerState<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends ConsumerState<UpdatesScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  DownloadState _downloadState = const DownloadState();
  late AnimationController _spinController;
  bool _isCheckingManually = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerCheck(isManual: false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _spinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check when returning to the app (e.g., after package installer finishes)
      _triggerCheck(isManual: false);
    }
  }

  Future<void> _triggerCheck({bool isManual = true}) async {
    if (isManual) {
      setState(() => _isCheckingManually = true);
      _spinController.repeat();
    }

    try {
      await ref.read(updateNotifierProvider.notifier).checkForUpdates();
    } finally {
      if (mounted) {
        if (isManual) {
          _spinController.stop();
          _spinController.reset();
          setState(() => _isCheckingManually = false);
        }
        // If app is already updated to latest, reset any leftover download state
        final currentState = ref.read(updateNotifierProvider);
        if (!currentState.isUpdateAvailable &&
            _downloadState.status != DownloadStatus.downloading) {
          setState(() {
            _downloadState = const DownloadState(status: DownloadStatus.idle);
          });
        }
      }
    }
  }

  Future<void> _startDownloadAndInstall(AppRelease release) async {
    if (release.downloadUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No download URL available for this release.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _downloadState = const DownloadState(
        status: DownloadStatus.downloading,
        progress: 0.0,
      );
    });

    try {
      final downloadService = ref.read(apkDownloadServiceProvider);

      final filePath = await downloadService.downloadApk(
        url: release.downloadUrl,
        version: release.version,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadState = _downloadState.copyWith(progress: progress);
            });
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _downloadState = DownloadState(
          status: DownloadStatus.downloaded,
          progress: 1.0,
          filePath: filePath,
        );
      });

      // Auto-trigger installer
      _installDownloadedApk(filePath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadState = DownloadState(
          status: DownloadStatus.failed,
          error: _humanReadableError(e),
        );
      });
    }
  }

  Future<void> _installDownloadedApk(String filePath) async {
    setState(() {
      _downloadState = _downloadState.copyWith(status: DownloadStatus.installing);
    });

    try {
      final downloadService = ref.read(apkDownloadServiceProvider);
      await downloadService.installApk(filePath);

      if (!mounted) return;
      setState(() {
        _downloadState = _downloadState.copyWith(status: DownloadStatus.downloaded);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadState = DownloadState(
          status: DownloadStatus.failed,
          filePath: filePath,
          error: 'Could not launch package installer: ${_humanReadableError(e)}',
        );
      });
    }
  }

  void _cancelDownload() {
    final downloadService = ref.read(apkDownloadServiceProvider);
    downloadService.cancelDownload();
    setState(() {
      _downloadState = const DownloadState(status: DownloadStatus.idle);
    });
  }

  Future<void> _openExternalBrowserDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open external browser link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _humanReadableError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Network') || msg.contains('connection')) {
      return 'Network connection failed. Please check your internet connection.';
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return 'The update package file could not be found on the server.';
    }
    if (msg.contains('Permission') || msg.contains('denied')) {
      return 'Storage permission denied. Please enable install permissions for Campusly.';
    }
    return 'Download error: $msg';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Approx. 28 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Updates & Releases',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          RotationTransition(
            turns: _spinController,
            child: IconButton(
              icon: Icon(
                LucideIcons.refreshCw,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              tooltip: 'Check for Updates',
              onPressed: _isCheckingManually ? null : () => _triggerCheck(isManual: true),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: updateState.isLoading && !_isCheckingManually
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _triggerCheck(isManual: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                children: [
                  // Error state if fetch failed
                  if (updateState.error != null)
                    _buildFetchErrorBanner(context, updateState.error!),

                  // Hero Status Card
                  if (updateState.isUpdateAvailable && updateState.latestRelease != null)
                    _buildUpdateAvailableHero(context, updateState.latestRelease!, updateState)
                  else
                    _buildUpToDateHero(context, updateState, isDark),

                  SizedBox(height: 28.h),

                  // Previous Releases Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Release History',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Official Builds',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  _buildPreviousReleasesList(context),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
    );
  }

  Widget _buildFetchErrorBanner(BuildContext context, String error) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, color: AppColors.coral, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Notice',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.coral,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Unable to sync with update server. Please check network connection.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: 10.h),
                InkWell(
                  onTap: () => _triggerCheck(isManual: true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.refreshCw, size: 14.sp, color: AppColors.coral),
                      SizedBox(width: 6.w),
                      Text(
                        'Tap to retry',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.coral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpToDateHero(BuildContext context, UpdateState state, bool isDark) {
    final theme = Theme.of(context);
    final versionStr = state.currentVersion ?? '1.1.0';
    final buildStr = state.currentBuildNumber != null ? 'Build ${state.currentBuildNumber}' : 'Build 2';
    final lastCheckedStr = state.lastCheckedAt != null
        ? DateFormat('h:mm a').format(state.lastCheckedAt!)
        : 'Just now';

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.mint.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated Pulse Badge
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.mint.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Icon(
              LucideIcons.shieldCheck,
              size: 44.sp,
              color: AppColors.mint,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            "You're completely up to date",
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.packageCheck, size: 14.sp, color: AppColors.primary),
                SizedBox(width: 6.w),
                Text(
                  'Campusly v$versionStr · $buildStr',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Your installation has the latest features, security patches, and timetable optimizations.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          Divider(color: AppColors.border),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 14.sp, color: AppColors.textSecondary),
                  SizedBox(width: 6.w),
                  Text(
                    'Checked today at $lastCheckedStr',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _isCheckingManually ? null : () => _triggerCheck(isManual: true),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.refreshCw,
                        size: 14.sp,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Check Now',
                        style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAvailableHero(
      BuildContext context, AppRelease release, UpdateState state) {
    final theme = Theme.of(context);
    final isCritical = release.priority == ReleasePriority.critical || state.isMandatory;
    final accentColor = isCritical ? AppColors.coral : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(22.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  color: accentColor,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            isCritical ? 'CRITICAL UPDATE' : 'NEW VERSION',
                            style: AppTypography.labelSmall.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.sp,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _formatFileSize(release.fileSizeBytes),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Version ${release.version}',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (release.publishedAt != null)
                      Text(
                        'Published on ${DateFormat.yMMMd().format(release.publishedAt!)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          if (release.title.isNotEmpty && release.title != 'Release') ...[
            Text(
              release.title,
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
          ],

          if (release.description != null && release.description!.isNotEmpty) ...[
            Text(
              release.description!,
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),
          ],

          if (release.releaseNotes.isNotEmpty) ...[
            Text(
              "What's New in this Build:",
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 10.h),
            ...release.releaseNotes.take(4).map((note) => _buildReleaseNoteItem(note)),
            SizedBox(height: 14.h),
          ],

          // Dynamic Download / Progress / Install Card
          _buildInteractiveDownloadSection(context, release, accentColor),
        ],
      ),
    );
  }

  Widget _buildInteractiveDownloadSection(
      BuildContext context, AppRelease release, Color accentColor) {
    switch (_downloadState.status) {
      case DownloadStatus.idle:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: () => _startDownloadAndInstall(release),
                icon: const Icon(LucideIcons.downloadCloud, size: 20),
                label: Text(
                  'Download & Install Update',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Center(
              child: TextButton.icon(
                onPressed: () => _openExternalBrowserDownload(release.downloadUrl),
                icon: Icon(LucideIcons.externalLink, size: 14.sp),
                label: Text(
                  'Or download APK in browser',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );

      case DownloadStatus.downloading:
        final progress = _downloadState.progress;
        final percent = (progress * 100).toInt();
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Downloading update...',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$percent%',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 10.h,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Campusly will prompt to install once finished',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                  InkWell(
                    onTap: _cancelDownload,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      child: Text(
                        'Cancel',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.coral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case DownloadStatus.downloaded:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_downloadState.filePath != null) {
                    _installDownloadedApk(_downloadState.filePath!);
                  }
                },
                icon: const Icon(LucideIcons.packageOpen, size: 20),
                label: Text(
                  'Ready to Install — Tap Here',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Package verified and downloaded to device cache',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );

      case DownloadStatus.installing:
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.mint.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.mint),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opening Package Installer...',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.mint,
                      ),
                    ),
                    Text(
                      'Follow on-screen prompt to finish updating',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case DownloadStatus.failed:
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.coral.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: AppColors.coral, size: 20.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Installation failed',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                _downloadState.error ?? 'An unexpected error occurred while downloading.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _startDownloadAndInstall(release),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(color: accentColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openExternalBrowserDownload(release.downloadUrl),
                      icon: const Icon(LucideIcons.externalLink, size: 16),
                      label: const Text('Open Browser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _buildReleaseNoteItem(ReleaseNote note) {
    Color getCategoryColor() {
      switch (note.category) {
        case NoteCategory.newFeature:
          return AppColors.primary;
        case NoteCategory.improved:
          return AppColors.mint;
        case NoteCategory.fixed:
          return AppColors.coral;
        case NoteCategory.security:
          return Colors.red;
        case NoteCategory.performance:
          return Colors.purple;
        case NoteCategory.design:
          return Colors.pink;
      }
    }

    String getCategoryLabel() {
      switch (note.category) {
        case NoteCategory.newFeature:
          return 'NEW';
        case NoteCategory.improved:
          return 'IMPROVED';
        case NoteCategory.fixed:
          return 'FIX';
        case NoteCategory.security:
          return 'SECURITY';
        case NoteCategory.performance:
          return 'PERFORMANCE';
        case NoteCategory.design:
          return 'DESIGN';
      }
    }

    final catColor = getCategoryColor();

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2.h, right: 10.w),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: catColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              getCategoryLabel(),
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: catColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.title != null && note.title!.isNotEmpty)
                  Text(
                    note.title!,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  note.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousReleasesList(BuildContext context) {
    return FutureBuilder<List<AppRelease>>(
      future: ref.read(updateNotifierProvider.notifier).getPreviousReleases(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.0.w),
              child: Text(
                'Could not load release archive.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final releases = snapshot.data ?? [];
        if (releases.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.0.w),
              child: Text(
                'No previous releases recorded.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: releases.length,
          separatorBuilder: (_, _) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final release = releases[index];
            final isLatest = index == 0;

            return InkWell(
              onTap: () => _showReleaseDetails(context, release),
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: isLatest
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        isLatest ? LucideIcons.sparkles : LucideIcons.archive,
                        size: 18.sp,
                        color: isLatest ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Version ${release.version}',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isLatest) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.mint.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'LATEST',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.mint,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            release.publishedAt != null
                                ? 'Released ${DateFormat.yMMMd().format(release.publishedAt!)}'
                                : 'Build #${release.buildNumber}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18.sp,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReleaseDetails(BuildContext context, AppRelease release) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 12.h),
              Center(
                child: Container(
                  width: 44.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Version ${release.version}',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (release.publishedAt != null)
                          Text(
                            'Released on ${DateFormat.yMMMd().format(release.publishedAt!)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    if (release.downloadUrl.isNotEmpty)
                      IconButton(
                        icon: const Icon(LucideIcons.externalLink),
                        tooltip: 'Open Download Link',
                        onPressed: () => _openExternalBrowserDownload(release.downloadUrl),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Divider(color: AppColors.border),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(24.0.w),
                  children: [
                    if (release.title.isNotEmpty && release.title != 'Release') ...[
                      Text(
                        release.title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                    if (release.description != null && release.description!.isNotEmpty) ...[
                      Text(
                        release.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                    Text(
                      'Release Notes & Changes:',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (release.releaseNotes.isEmpty)
                      Text(
                        'No granular change items listed for this release.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      )
                    else
                      ...release.releaseNotes.map((note) => _buildReleaseNoteItem(note)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
