class PayMobConfig {
  final String apiKey;
  final String integrationId;
  final String iframeId;
  bool isTest;

  PayMobConfig({
    required this.apiKey,
    required this.integrationId,
    required this.iframeId,
    this.isTest = false,
  });
} 