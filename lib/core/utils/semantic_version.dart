class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;
  final String? buildMetadata;

  SemanticVersion({
    this.major = 0,
    this.minor = 0,
    this.patch = 0,
    this.preRelease,
    this.buildMetadata,
  });

  factory SemanticVersion.parse(String versionString) {
    final clean = versionString.trim();
    if (clean.isEmpty) {
      return SemanticVersion();
    }
    
    // Support semver with optional 'v'/'V' prefix and optional build suffix
    final regex = RegExp(
        r'^[vV]?(0|[1-9]\d*)\.(0|[1-9]\d*)(?:\.(0|[1-9]\d*))?(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$');
    
    final match = regex.firstMatch(clean);
    if (match == null) {
      // Fallback for simple versions like "1.0", "2", or "1.1.0+2"
      final withoutV = clean.replaceAll(RegExp(r'^[vV]'), '');
      final withoutBuild = withoutV.split('+')[0].split('-')[0];
      final parts = withoutBuild.split('.');
      final buildPart = clean.contains('+') ? clean.split('+')[1] : null;
      return SemanticVersion(
        major: parts.isNotEmpty ? int.tryParse(parts[0].trim()) ?? 0 : 0,
        minor: parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0,
        patch: parts.length > 2 ? int.tryParse(parts[2].trim()) ?? 0 : 0,
        buildMetadata: buildPart,
      );
    }

    return SemanticVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: match.group(3) != null ? int.parse(match.group(3)!) : 0,
      preRelease: match.group(4),
      buildMetadata: match.group(5),
    );
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    
    // Pre-release versions have a lower precedence than the associated normal version
    if (preRelease == null && other.preRelease != null) return 1;
    if (preRelease != null && other.preRelease == null) return -1;
    
    // String comparison for prerelease
    if (preRelease != null && other.preRelease != null) {
      final prCompare = preRelease!.compareTo(other.preRelease!);
      if (prCompare != 0) return prCompare;
    }

    // Numerical/string buildMetadata comparison fallback for mobile versioning
    if (buildMetadata != null && other.buildMetadata != null) {
      final b1 = int.tryParse(buildMetadata!);
      final b2 = int.tryParse(other.buildMetadata!);
      if (b1 != null && b2 != null && b1 != b2) {
        return b1.compareTo(b2);
      }
      return buildMetadata!.compareTo(other.buildMetadata!);
    }
    
    return 0;
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemanticVersion && compareTo(other) == 0;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);
  
  @override
  String toString() {
    var str = '$major.$minor.$patch';
    if (preRelease != null) str += '-$preRelease';
    if (buildMetadata != null) str += '+$buildMetadata';
    return str;
  }
}
