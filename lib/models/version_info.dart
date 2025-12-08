class VersionInfo {
  const VersionInfo({
    this.mobileVersion,
    this.apiVersion,
    this.webVersion,
    this.minimumMobileVersion,
  });

  final String? mobileVersion;
  final String? apiVersion;
  final String? webVersion;
  final String? minimumMobileVersion;

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    String? pick(dynamic value) =>
        value == null ? null : value.toString().trim();

    return VersionInfo(
      mobileVersion:
          pick(json['mobile_version'] ?? json['mobileVersion'] ?? json['mobile']),
      apiVersion: pick(json['api_version'] ?? json['apiVersion'] ?? json['api']),
      webVersion: pick(json['web_version'] ?? json['webVersion'] ?? json['web']),
      minimumMobileVersion: pick(
        json['min_mobile_version'] ??
            json['minimum_mobile_version'] ??
            json['minMobileVersion'],
      ),
    );
  }
}
