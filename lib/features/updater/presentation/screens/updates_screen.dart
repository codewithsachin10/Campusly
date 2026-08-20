import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import 'package:campusly/features/updater/data/models/app_release.dart';
import 'package:campusly/features/updater/data/services/update_service.dart';
import 'package:campusly/features/updater/data/services/apk_download_service.dart';

class UpdatesScreen extends ConsumerStatefulWidget {
  const UpdatesScreen({super.key});

  @override
  ConsumerState<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends ConsumerState<UpdatesScreen> {
  DownloadState _downloadState = DownloadState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateNotifierProvider.notifier).checkForUpdates();
    });
  }

  Future<void> _startDownloadAndInstall(AppRelease release) async {
    if (release.downloadUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No download URL available for this release.')),
      );
      return;
    }

    setState(() {
      _downloadState = DownloadState(status: DownloadStatus.downloading, progress: 0.0);
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

      // Auto-trigger install
      setState(() {
        _downloadState = _downloadState.copyWith(status: DownloadStatus.installing);
      });

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
          error: e.toString(),
        );
      });
    }
  }

  void _cancelDownload() {
    final downloadService = ref.read(apkDownloadServiceProvider);
    downloadService.cancelDownload();
    setState(() {
      _downloadState = DownloadState(status: DownloadStatus.idle);
    });
  }

  void _retryInstall() async {
    if (_downloadState.filePath != null) {
      setState(() {
        _downloadState = _downloadState.copyWith(status: DownloadStatus.installing);
      });
      try {
        final downloadService = ref.read(apkDownloadServiceProvider);
        await downloadService.installApk(_downloadState.filePath!);
        if (!mounted) return;
        setState(() {
          _downloadState = _downloadState.copyWith(status: DownloadStatus.downloaded);
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _downloadState = DownloadState(
            status: DownloadStatus.failed,
            error: e.toString(),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Updates Center'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: updateState.isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(updateNotifierProvider.notifier).checkForUpdates(),
              child: ListView(
                padding: EdgeInsets.all(16.0.w),
                children: [
                  _buildStatusHeader(context, updateState),
                  SizedBox(height: 24.h),
                  if (updateState.latestRelease != null)
                    _buildLatestReleaseCard(
                        context, updateState.latestRelease!, updateState),
                  SizedBox(height: 24.h),
                  Text(
                    'Previous Releases',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildPreviousReleasesList(context),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, UpdateState state) {
    final theme = Theme.of(context);
    final isUpToDate = !state.isUpdateAvailable;
    final color = isUpToDate ? Colors.green : theme.colorScheme.primary;
    final icon = isUpToDate ? LucideIcons.checkCircle2 : LucideIcons.downloadCloud;
    final title = isUpToDate ? 'You\'re up to date!' : 'Update Available';

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          SizedBox(height: 16.h),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Current Version: ${state.currentVersion ?? 'Unknown'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestReleaseCard(
      BuildContext context, AppRelease release, UpdateState state) {
    final theme = Theme.of(context);
    final isCritical = release.priority == ReleasePriority.critical;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: isCritical
              ? Colors.red.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: 1.w,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Version ${release.version}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isCritical
                        ? Colors.red.withValues(alpha: 0.1)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    isCritical ? 'Critical Update' : 'Latest Release',
                    style: TextStyle(
                      color: isCritical ? Colors.red : theme.colorScheme.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (release.publishedAt != null) ...[
              SizedBox(height: 8.h),
              Text(
                'Released ${DateFormat.yMMMd().format(release.publishedAt!)}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 12.sp,
                ),
              ),
            ],
            SizedBox(height: 16.h),
            if (release.description != null) ...[
              Text(
                release.description!,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 16.h),
            ],
            if (release.releaseNotes.isNotEmpty)
              ...release.releaseNotes.map((note) => _buildReleaseNoteItem(note)),
            SizedBox(height: 24.h),
            // ── Download / Install Button Area ──
            _buildDownloadButton(context, release, state),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
      BuildContext context, AppRelease release, UpdateState state) {
    final theme = Theme.of(context);
    final isCritical = release.priority == ReleasePriority.critical;
    final buttonColor = isCritical ? Colors.red : theme.colorScheme.primary;

    switch (_downloadState.status) {
      case DownloadStatus.idle:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: state.isUpdateAvailable
                ? () => _startDownloadAndInstall(release)
                : null,
            icon: Icon(LucideIcons.download, size: 20),
            label: Text(
              state.isUpdateAvailable ? 'Download & Install' : 'Already Installed',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        );

      case DownloadStatus.downloading:
        final percent = (_downloadState.progress * 100).toInt();
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: _downloadState.progress,
                minHeight: 8,
                backgroundColor: buttonColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Downloading... $percent%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: _cancelDownload,
                  child: Text('Cancel'),
                ),
              ],
            ),
          ],
        );

      case DownloadStatus.downloaded:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _retryInstall,
            icon: Icon(LucideIcons.packageOpen, size: 20),
            label: Text(
              'Install Now',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        );

      case DownloadStatus.installing:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: null,
            icon: SizedBox(
              width: 20.w,
              height: 20.h,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            label: Text(
              'Installing...',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        );

      case DownloadStatus.failed:
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Download failed. Please try again.',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _startDownloadAndInstall(release),
                icon: Icon(LucideIcons.refreshCw, size: 20),
                label: Text(
                  'Retry Download',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildReleaseNoteItem(ReleaseNote note) {
    Color getCategoryColor() {
      switch (note.category) {
        case NoteCategory.newFeature:
          return Colors.blue;
        case NoteCategory.improved:
          return Colors.green;
        case NoteCategory.fixed:
          return Colors.orange;
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

    return Padding(
      padding: EdgeInsets.only(bottom: 12.0.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2.h, right: 12.w),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: getCategoryColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: getCategoryColor().withValues(alpha: 0.3)),
            ),
            child: Text(
              getCategoryLabel(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: getCategoryColor(),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.title != null)
                  Text(
                    note.title!,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                Text(
                  note.description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4.h,
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
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading history: ${snapshot.error}'));
        }

        final releases = snapshot.data ?? [];
        if (releases.length <= 1) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.0.w),
              child: Text('No previous releases found.'),
            ),
          );
        }

        // Skip the first one as it's the latest release shown above
        final previousReleases = releases.skip(1).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: previousReleases.length,
          separatorBuilder: (_, _) => Divider(),
          itemBuilder: (context, index) {
            final release = previousReleases[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Version ${release.version}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(release.publishedAt != null
                  ? DateFormat.yMMMd().format(release.publishedAt!)
                  : 'Unknown date'),
              trailing: Icon(LucideIcons.chevronRight, size: 20),
              onTap: () {
                _showReleaseDetails(context, release);
              },
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 12.h),
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                child: Text(
                  'Version ${release.version}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (release.publishedAt != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.h),
                  child: Text(
                    'Released ${DateFormat.yMMMd().format(release.publishedAt!)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              Divider(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(24.0.w),
                  children: [
                    if (release.description != null) ...[
                      Text(
                        release.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 24.h),
                    ],
                    if (release.releaseNotes.isEmpty)
                      Text('No detailed release notes available.')
                    else
                      ...release.releaseNotes
                          .map((note) => _buildReleaseNoteItem(note)),
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
