class AppReleaseInfo {
  const AppReleaseInfo({
    required this.name,
    required this.version,
    required this.buildNumber,
    required this.releaseChannel,
  });

  final String name;
  final String version;
  final String buildNumber;
  final String releaseChannel;
}

const appReleaseInfo = AppReleaseInfo(
  name: 'Moniary',
  version: '1.0.0',
  buildNumber: '1',
  releaseChannel: 'MVP',
);
