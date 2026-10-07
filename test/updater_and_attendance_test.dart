import 'package:flutter_test/flutter_test.dart';
import 'package:campusly/core/utils/semantic_version.dart';

void main() {
  group('SemanticVersion and Smart Updater Logic Tests', () {
    test('parses standard semver strings correctly', () {
      final v1 = SemanticVersion.parse('1.1.0');
      expect(v1.major, 1);
      expect(v1.minor, 1);
      expect(v1.patch, 0);
      expect(v1.buildMetadata, isNull);
    });

    test('handles leading v and V prefixes and whitespace', () {
      final v1 = SemanticVersion.parse('v1.2.3');
      final v2 = SemanticVersion.parse('V1.2.3');
      final v3 = SemanticVersion.parse('  1.2.3  ');

      expect(v1.major, 1);
      expect(v1.minor, 2);
      expect(v1.patch, 3);
      expect(v2.major, 1);
      expect(v2.minor, 2);
      expect(v2.patch, 3);
      expect(v3.major, 1);
      expect(v3.minor, 2);
      expect(v3.patch, 3);
    });

    test('parses version with build metadata and compares precedence', () {
      final v1 = SemanticVersion.parse('1.1.0+1');
      final v2 = SemanticVersion.parse('1.1.0+2');

      expect(v1.major, 1);
      expect(v1.minor, 1);
      expect(v1.patch, 0);
      expect(v1.buildMetadata, '1');
      expect(v2.buildMetadata, '2');

      expect(v2 > v1, isTrue);
      expect(v1 < v2, isTrue);
      expect(v1 == v1, isTrue);
    });

    test('correctly identifies when user is already up-to-date', () {
      final currentVersion = SemanticVersion.parse('1.1.0');
      const currentBuild = 2;

      final remoteVersion = SemanticVersion.parse('1.1.0');
      const remoteBuild = 2;

      final isNewerVersion = remoteVersion > currentVersion;
      final isNewerBuild = (remoteVersion == currentVersion) && (remoteBuild > currentBuild);
      final isUpdateAvailable = isNewerVersion || isNewerBuild;

      expect(isUpdateAvailable, isFalse);
    });

    test('correctly identifies update when remote build is higher', () {
      final currentVersion = SemanticVersion.parse('1.1.0');
      const currentBuild = 2;

      final remoteVersion = SemanticVersion.parse('1.1.0');
      const remoteBuild = 3;

      final isNewerVersion = remoteVersion > currentVersion;
      final isNewerBuild = (remoteVersion == currentVersion) && (remoteBuild > currentBuild);
      final isUpdateAvailable = isNewerVersion || isNewerBuild;

      expect(isUpdateAvailable, isTrue);
    });

    test('correctly identifies update when remote version is higher', () {
      final currentVersion = SemanticVersion.parse('1.1.0');
      const currentBuild = 2;

      final remoteVersion = SemanticVersion.parse('1.2.0');
      const remoteBuild = 1;

      final isNewerVersion = remoteVersion > currentVersion;
      final isNewerBuild = (remoteVersion == currentVersion) && (remoteBuild > currentBuild);
      final isUpdateAvailable = isNewerVersion || isNewerBuild;

      expect(isUpdateAvailable, isTrue);
    });

    test('guards against false positive when user local build is ahead of remote', () {
      final currentVersion = SemanticVersion.parse('1.2.0');
      const currentBuild = 5;

      final remoteVersion = SemanticVersion.parse('1.1.0');
      const remoteBuild = 2;

      bool isUpdateAvailable = false;
      if (remoteVersion > currentVersion) {
        isUpdateAvailable = true;
      } else if (remoteVersion == currentVersion && remoteBuild > currentBuild) {
        isUpdateAvailable = true;
      }

      if (currentVersion > remoteVersion || (currentVersion == remoteVersion && currentBuild >= remoteBuild)) {
        isUpdateAvailable = false;
      }

      expect(isUpdateAvailable, isFalse);
    });
  });
}
