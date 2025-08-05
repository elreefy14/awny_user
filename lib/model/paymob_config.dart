class PayMobConfig {
  final String apiKey;
  final String integrationId;
  final String iframeId;
  final List<String>? allIntegrationIds;
  final String? walletIntegrationId;
  final String? walletIframeId;
  bool isTest;

  PayMobConfig({
    required this.apiKey,
    required this.integrationId,
    required this.iframeId,
    this.allIntegrationIds,
    this.walletIntegrationId,
    this.walletIframeId,
    this.isTest = false,
  });
}
