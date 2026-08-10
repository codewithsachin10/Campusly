import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/version_check_service.dart';
import '../../data/services/apk_installer_service.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  final AppReleaseInfo releaseInfo;

  const UpdateDialog({
    Key? key,
    required this.releaseInfo,
  }) : super(key: key);

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _errorMessage;

  bool get _isMandatory => widget.releaseInfo.updateType == UpdateType.MANDATORY;

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    final installer = ref.read(apkInstallerServiceProvider);
    
    // Get current build for analytics
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

    try {
      await installer.logAnalytics(
        fromBuild: currentBuild,
        toBuild: widget.releaseInfo.buildNumber,
        status: 'STARTED',
      );

      final filePath = await installer.downloadApk(
        widget.releaseInfo,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      if (filePath == null) {
        throw Exception("Failed to download the update package.");
      }
      
      setState(() {
        _progress = 1.0; 
        _errorMessage = "Verifying security signature...";
      });

      // Verify SHA-256
      final isValid = await installer.verifyApkHash(filePath, widget.releaseInfo.apkSha256);
      
      if (!isValid) {
        await installer.logAnalytics(
          fromBuild: currentBuild,
          toBuild: widget.releaseInfo.buildNumber,
          status: 'INTEGRITY_FAILED',
          errorMessage: 'SHA-256 Hash mismatch',
        );
        throw Exception("Security check failed. The downloaded file is corrupted or tampered with. Please try again.");
      }

      await installer.logAnalytics(
        fromBuild: currentBuild,
        toBuild: widget.releaseInfo.buildNumber,
        status: 'DOWNLOADED',
      );

      setState(() {
        _errorMessage = "Installing...";
      });

      final installSuccess = await installer.installApk(filePath);
      
      if (!installSuccess) {
        throw Exception("Failed to trigger the Android installer.");
      }

      setState(() {
        _isDownloading = false;
        _errorMessage = null;
      });
      
    } catch (e) {
      final errorMsg = e.toString().replaceAll("Exception: ", "");
      await installer.logAnalytics(
        fromBuild: currentBuild,
        toBuild: widget.releaseInfo.buildNumber,
        status: 'FAILED',
        errorMessage: errorMsg,
      );
      
      setState(() {
        _isDownloading = false;
        _errorMessage = errorMsg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecommended = widget.releaseInfo.updateType == UpdateType.RECOMMENDED;
    
    Color headerColor = Colors.blue;
    IconData headerIcon = LucideIcons.rocket;
    
    if (_isMandatory) {
      headerColor = Colors.red;
      headerIcon = LucideIcons.alertTriangle;
    } else if (isRecommended) {
      headerColor = Colors.orange;
      headerIcon = LucideIcons.star;
    }

    return PopScope(
      canPop: !_isMandatory && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  headerIcon,
                  color: headerColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                widget.releaseInfo.releaseTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              
              // Version info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Version ${widget.releaseInfo.version} (${(widget.releaseInfo.apkSize / (1024 * 1024)).toStringAsFixed(1)} MB)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Release Notes Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "What's New",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.releaseInfo.releaseNotes.isNotEmpty 
                          ? widget.releaseInfo.releaseNotes 
                          : 'Bug fixes and performance improvements to keep Campusly running smoothly.',
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error Message
              if (_errorMessage != null && !_isDownloading) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Security info
              if (!_isDownloading && _errorMessage == null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 14, color: Colors.green[600]),
                    const SizedBox(width: 6),
                    Text(
                      "Verified via SHA-256",
                      style: TextStyle(fontSize: 12, color: Colors.green[600], fontWeight: FontWeight.w500),
                    )
                  ],
                ),
                
              const SizedBox(height: 16),

              // Progress Bar or Actions
              if (_isDownloading) ...[
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: AppColors.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage ?? 'Downloading... ${(_progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant, 
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              ] else ...[
                Row(
                  children: [
                    if (!_isMandatory) ...[
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Later', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: _isMandatory ? 1 : 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _startUpdate,
                        child: Text(
                          _errorMessage != null ? 'Try Again' : 'Update Now',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
