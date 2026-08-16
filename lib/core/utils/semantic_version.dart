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
    if (versionString.isEmpty) {
      return SemanticVersion();
    }
    
    // Simple semver regex
    final regex = RegExp(
        r'^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$');
    
    final match = regex.firstMatch(versionString);
    if (match == null) {
      // Fallback for simple versions like "1.0" or "2"
      final parts = versionString.replaceAll('v', '').split('.');
      return SemanticVersion(
        major: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
        minor: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        patch: parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
      );
    }

    return SemanticVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
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
    
    // Simple string comparison for prerelease for now
    if (preRelease != null && other.preRelease != null) {
      return preRelease!.compareTo(other.preRelease!);
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
